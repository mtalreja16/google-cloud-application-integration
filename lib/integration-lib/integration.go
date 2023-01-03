package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	cors "github.com/rs/cors"
	integrations "google.golang.org/api/integrations/v1alpha"
)

func main() {
	ctx := context.Background()
	var err error
	integrationsService, err := integrations.NewService(ctx)
	mux := http.NewServeMux()
	var jsonBody []byte

	mux.HandleFunc("/run", func(w http.ResponseWriter, r *http.Request) {
		setupCorsResponse(&w, r)
		if r.Method != http.MethodPost {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		body, err := io.ReadAll(r.Body)

		if err != nil {
			http.Error(w, "Error reading request body", http.StatusBadRequest)
			return
		}
		// Set the body to a variable

		project := r.URL.Query().Get("project")
		if project == "" {
			http.Error(w, "Missing parameter project", http.StatusBadRequest)
			return
		}
		region := r.URL.Query().Get("region")
		if region == "" {
			http.Error(w, "Missing parameter region", http.StatusBadRequest)
			return
		}
		name := r.URL.Query().Get("name")
		if name == "" {
			http.Error(w, "Missing parameter name", http.StatusBadRequest)
			return
		}
		trigger := "api_trigger/" + r.URL.Query().Get("trigger")
		if trigger == "" {
			http.Error(w, "Missing parameter trigger", http.StatusBadRequest)
			return
		}

		jsonBody, err = execIntegration(integrationsService, project, region, name, trigger, string(body))

		if err != nil {
			json.NewEncoder(w).Encode(err)
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write(jsonBody)
	})

	mux.HandleFunc("/resume", func(w http.ResponseWriter, r *http.Request) {

		if r.Method != http.MethodPost {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		project := r.URL.Query().Get("project")
		if project == "" {
			http.Error(w, "Missing parameter project", http.StatusBadRequest)
			return
		}
		region := r.URL.Query().Get("region")
		if region == "" {
			http.Error(w, "Missing parameter region", http.StatusBadRequest)
			return
		}
		name := r.URL.Query().Get("name")
		if name == "" {
			http.Error(w, "Missing parameter name", http.StatusBadRequest)
			return
		}
		executionId := r.URL.Query().Get("executionId")
		if executionId == "" {
			http.Error(w, "Missing parameter executionId", http.StatusBadRequest)
			return
		}

		jsonBody, err = liftIntegration(integrationsService, project, region, name, executionId)
		if err != nil {
			json.NewEncoder(w).Encode(err)
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write(jsonBody)
	})

	handler := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "DELETE", "OPTIONS"},
		AllowCredentials: true}).Handler(mux)

	http.ListenAndServe(":8080", handler)
}
func setupCorsResponse(w *http.ResponseWriter, r *http.Request) {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
	(*w).Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Authorization")
}

func execIntegration(integrationsService *integrations.Service, project string, location string, name string, triggerId string, body string) ([]byte, error) {
	//construct the parent
	parent := fmt.Sprintf("projects/%s/locations/%s/integrations/%s", project, location, name)
	request := integrations.GoogleCloudIntegrationsV1alphaExecuteIntegrationsRequest{}
	request.TriggerId = triggerId

	request.InputParameters = make(map[string]integrations.GoogleCloudIntegrationsV1alphaValueType)
	// Define a map to store the key-value pairs
	var result map[string]interface{}
	// Unmarshal the JSON object into the map
	json.Unmarshal([]byte(body), &result)

	for key, value := range result {
		valtype := integrations.GoogleCloudIntegrationsV1alphaValueType{JsonValue: value.(string)}
		request.InputParameters[key] = valtype
	}

	executionResponse, err := integrationsService.Projects.Locations.Integrations.Execute(parent, &request).Do()
	if err != nil {
		fmt.Println(err)
		return nil, err
	}
	//convert the response to json
	jsonBody, err := executionResponse.MarshalJSON()
	if err != nil {
		fmt.Println(err)
		return nil, err
	}
	return jsonBody, nil
}

func liftIntegration(integrationsService *integrations.Service, project string, location string, name string, executionId string) ([]byte, error) {
	//construct the parent

	parent := fmt.Sprintf("projects/%s/locations/%s/integrations/%s/executions/%s/-", project, location, name, executionId)

	client := integrations.NewProjectsLocationsProductsIntegrationsExecutionsSuspensionsService(integrationsService)

	suspensionRequest := integrations.GoogleCloudIntegrationsV1alphaLiftSuspensionRequest{}
	suspensionRequest.SuspensionResult = "Done"

	response, err := client.Lift(parent, &suspensionRequest).Do()

	if err != nil {
		fmt.Println(err)
		return nil, err
	}
	//convert the response to json
	jsonBody, err := response.MarshalJSON()
	if err != nil {
		fmt.Println(err)
		return nil, err
	}
	return jsonBody, nil
}
