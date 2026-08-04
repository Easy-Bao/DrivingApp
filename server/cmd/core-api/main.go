package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/ent"
	"github.com/Easy-Bao/DrivingApp/server/ent/migrate"
	adminpostgres "github.com/Easy-Bao/DrivingApp/server/internal/admin/adapter/postgres"
	adminhttp "github.com/Easy-Bao/DrivingApp/server/internal/admin/transport/http"
	adminusecase "github.com/Easy-Bao/DrivingApp/server/internal/admin/usecase"
	authpostgres "github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/postgres"
	"github.com/Easy-Bao/DrivingApp/server/internal/auth/adapter/token"
	authhttp "github.com/Easy-Bao/DrivingApp/server/internal/auth/transport/http"
	authusecase "github.com/Easy-Bao/DrivingApp/server/internal/auth/usecase"
	documentpostgres "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/adapter/postgres"
	documentstorage "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/adapter/storage"
	documenthttp "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/transport/http"
	documentusecase "github.com/Easy-Bao/DrivingApp/server/internal/driver_doc/usecase"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/adapter/mapbox"
	locationhttp "github.com/Easy-Bao/DrivingApp/server/internal/location/transport/http"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/usecase"
	ridespostgres "github.com/Easy-Bao/DrivingApp/server/internal/rides/adapter/postgres"
	rideshttp "github.com/Easy-Bao/DrivingApp/server/internal/rides/transport/http"
	ridesusecase "github.com/Easy-Bao/DrivingApp/server/internal/rides/usecase"
	userspostgres "github.com/Easy-Bao/DrivingApp/server/internal/users/adapter/postgres"
	usershttp "github.com/Easy-Bao/DrivingApp/server/internal/users/transport/http"
	usersusecase "github.com/Easy-Bao/DrivingApp/server/internal/users/usecase"
	_ "github.com/lib/pq"
)

func main() {
	router := http.NewServeMux()
	var authRouter *authhttp.Router
	var usersRouter *usershttp.Router
	var documentRouter *documenthttp.Router
	var ridesRouter *rideshttp.Router
	var adminRouter *adminhttp.Router
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		client, err := ent.Open("postgres", databaseURL)
		if err != nil {
			log.Fatal(err)
		}
		if err := client.Schema.Create(context.Background(), migrate.WithForeignKeys(true)); err != nil {
			log.Fatal(err)
		}
		defer client.Close()
		authRepository := authpostgres.NewUserRepository(client)
		authRouter = authhttp.NewRouter(authusecase.NewRegisterService(authRepository, token.NewIssuer(os.Getenv("JWT_SECRET"))), authusecase.NewAuthenticateService(authRepository, token.NewIssuer(os.Getenv("JWT_SECRET"))))
		verifier := token.NewVerifier(os.Getenv("JWT_SECRET"))
		usersRouter = usershttp.NewRouter(usersusecase.NewService(userspostgres.NewProfileRepository(client)), verifier)
		documentRouter = documenthttp.NewRouter(documentusecase.NewService(documentpostgres.NewRepository(client), documentstorage.LocalStorage{}), verifier)
		ridesRouter = rideshttp.NewRouter(ridesusecase.NewService(ridespostgres.NewRepository(client)), verifier)
		adminRouter = adminhttp.NewRouter(adminusecase.NewService(adminpostgres.NewRepository(client)), verifier)
	} else {
		log.Fatal("DATABASE_URL is required")
	}
	if authRouter != nil {
		authRouter.RegisterRoutes(router)
	}
	if usersRouter != nil {
		usersRouter.RegisterRoutes(router)
	}
	if documentRouter != nil {
		documentRouter.RegisterRoutes(router)
	}
	if ridesRouter != nil {
		ridesRouter.RegisterRoutes(router)
	}
	if adminRouter != nil {
		adminRouter.RegisterRoutes(router)
	}
	provider := mapbox.NewProvider(os.Getenv("MAPBOX_ACCESS_TOKEN"))
	locationhttp.NewHandler(usecase.NewService(provider)).RegisterRoutes(router)
	router.HandleFunc("GET /health", func(writer http.ResponseWriter, _ *http.Request) {
		writer.Header().Set("Content-Type", "application/json")
		_, _ = writer.Write([]byte(`{"status":"ok","service":"core-api"}`))
	})

	server := &http.Server{
		Addr:              ":" + port("CORE_API_PORT", "8080"),
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("core-api listening on %s", server.Addr)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
}

func port(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
