# CourtMate — Project Overview 

## Purpose

CourtMate is a small microservice-based platform for discovering and booking sports courts. The `CourtMate UI` is a Next.js frontend that consumes the platform's backend services (User, Court, Booking, Notifications) and provides the user-facing experience.

## What the project contains (quick)

- `Courtmate-ui`: Next.js 16 app (App Router) — the frontend application
- `Courtmate-User-Service`: FastAPI auth and user management service
- `Courtmate-Court-Service`: FastAPI courts/facilities and geolocation
- `Courtmate-Booking-Service`: FastAPI booking/reservation service
- `Courtmate-Notifications-Service`: Email notifications and scheduler
- `Courtmate-Infra`: Kubernetes / AKS deployment manifests and infra docs


## Key environment variables (frontend)

- `NEXTAUTH_URL` — URL where UI runs (e.g., `http://localhost:3000`)
- `AUTH_SECRET` — NextAuth secret
- `NEXT_PUBLIC_USER_SERVICE_URL` — backend user service base URL
- `NEXT_PUBLIC_FACILITIES_SERVICE_URL` — backend court service base URL
- `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` — Google Maps API key (for nearby courts)


## Where to find more

- Frontend specifics: See `Courtmate-ui/README.md` for full developer instructions and env details
- Backend specifics: See each service README (`Courtmate-User-Service/README.md`, `Courtmate-Court-Service/README.md`, `Courtmate-Booking-Service/README.md`, `Courtmate-Notifications-Service/README.md`)
- Infra: `Courtmate-Infra/README.md` (production AKS and deployment notes)
