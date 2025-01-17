package commands_test

import (
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	apiv1 "github.com/substratusai/substratus/api/v1"
	"github.com/substratusai/substratus/kubectl/internal/commands"
	"k8s.io/apimachinery/pkg/types"
)

func TestApplyBuild(t *testing.T) {
	cmd := commands.ApplyBuild()
	cmd.SetArgs([]string{
		"--filename", "./test-applybuild/notebook.yaml",
		"--kubeconfig", kubectlKubeconfigPath,
		//"-v=9",
		"./test-applybuild",
	})
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		if err := cmd.Execute(); err != nil {
			t.Error(err)
		}
	}()

	var uploadedPath string
	var uploadedPathMtx sync.Mutex
	mockBucketServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Log("mockBucketServer handler called")

		uploadedPathMtx.Lock()
		uploadedPath = r.URL.String()
		uploadedPathMtx.Unlock()
	}))
	defer mockBucketServer.Close()

	nb := &apiv1.Notebook{
		ObjectMeta: metav1.ObjectMeta{
			Name:      "test-applybuild",
			Namespace: "default",
		},
	}
	require.EventuallyWithT(t, func(t *assert.CollectT) {
		err := k8sClient.Get(ctx, types.NamespacedName{Namespace: nb.Namespace, Name: nb.Name}, nb)
		assert.NoError(t, err, "getting notebook")
	}, timeout, interval, "waiting for the notebook to be created")

	nb.Status.BuildUpload = apiv1.UploadStatus{
		SignedURL: mockBucketServer.URL + "/some-signed-url",
		RequestID: testUUID,
	}
	require.NoError(t, k8sClient.Status().Update(ctx, nb))

	require.EventuallyWithT(t, func(t *assert.CollectT) {
		uploadedPathMtx.Lock()
		assert.Equal(t, "/some-signed-url", uploadedPath)
		uploadedPathMtx.Unlock()
	}, timeout, interval, "waiting for command to upload the tarball")

	t.Log("wait group waiting")
	wg.Wait()
}
