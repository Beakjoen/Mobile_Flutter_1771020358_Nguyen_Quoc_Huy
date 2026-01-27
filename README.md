# PCM - Pickleball Club Management (Mobile Edition)

## Project Structure
- **Backend**: ASP.NET Core Web API (Folder: `Backend/PcmBackend`)
- **Mobile**: Flutter App (Folder: `Mobile/pcm_mobile`)

## Prerequisites
- .NET SDK 10.0
- Flutter SDK
- SQL Server (LocalDB or full instance)

## How to Run

### 1. Backend
1. Navigate to `Backend/PcmBackend`:
   ```bash
   cd Backend/PcmBackend
   ```
2. Update database (if not already done):
   ```bash
   dotnet ef database update
   ```
3. Run the API:
   ```bash
   dotnet run
   ```
   API will be available at `http://localhost:5000` (http) or `https://localhost:5001` (https).
   Swagger UI: `http://localhost:5000/swagger`

### 2. Mobile App
1. Navigate to `Mobile/pcm_mobile`:
   ```bash
   cd Mobile/pcm_mobile
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
   **Note**: 
   - If running on Android Emulator, the API base URL is configured as `http://10.0.2.2:5000/api`.
   - If running on iOS Simulator or Real Device, update `lib/services/api_service.dart` with your machine's IP address.

## Features Implemented
- **Backend**:
  - Entity Framework Core with SQL Server.
  - Identity Authentication (JWT).
  - Models: Member, Wallet, Booking, Tournament, Match, etc.
  - SignalR Hub for real-time updates.
  - Controllers for Auth, Members, Wallet, Bookings, Tournaments.
- **Mobile**:
  - Flutter project structure with Provider state management.
  - Login Screen with JWT storage.
  - Home Screen / Dashboard.
  - API Service with Dio & Interceptors.
  - SignalR Client integration.

## Student Info
NguyenQuocHuy - 1771020358
