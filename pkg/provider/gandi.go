package provider

import "github.com/prasmussen/gandi-api/client"

func newClient(apiKey string) *client.Client {
	return client.New(apiKey, client.Production)
}
