Implementation Plan: Ride-Hailing App Bug Fixes & Architecture Optimization
🛠️ Section 1: Bug & Issue Categorization
1. Network Isolation & Authentication Failures
The Issue: Driver credentials fail to authenticate on the Android emulator with a network connection error (ClientException with SocketException), but the exact same credentials work perfectly on physical devices.

The Description: The emulator runs inside an isolated virtual network where localhost or 127.0.0.1 refers to the emulator itself rather than the development machine running the backend microservices. Traffic sent to local loopback addresses cannot resolve the multi-port server architecture natively.

2. Passive Permission Failures & Location Hardware Blackouts (Physical Devices)
The Issue: Location services fail silently on physical devices in the Passenger application; the app cannot accurately acquire the user's localized coordinates or map context, and it fails to prompt the user to activate or turn on system location services when the device's hardware GPS is disabled.

The Description: A critical failure in the device runtime check pipeline. The application code attempts to query geographic coordinates without first validating whether the platform's location service providers (GPS/Network) are active, and it lacks the mandatory imperative bridge required to request hardware service activation via a system dialog.

3. Data Contract & Serialization Mismatches
The Issue: The ₱0.00 fare anomaly where the driver's pool feed and matching states display a zero balance while the passenger side correctly renders the actual trip fare (e.g., ₱25.00).

The Description: A structural failure in mapping numeric data types, null values, or missing key fields across microservice boundary layers during JSON deserialization.

4. State & Context Disconnects
The Issue: Active passenger identity shifting unexpectedly (e.g., from xyrel to Juan D. Cruz) when moving from the waiting screen into the active InTransit trip flow.

The Description: Navigation routing parameters failing to pass, serialize, or retain the real-time runtime session data block when executing screen transformations.

5. Hardcoded Location Address Placeholders in UI Summaries
The Issue: The trip cards and summary screens default to rendering the literal text string "Current Location" for the pick-up slot and static placeholders (like "Address here") for the drop-off slot instead of showing the actual geocoded physical addresses of the journey.

The Description: The text components within the layout widgets are hardcoded to raw string fallbacks rather than dynamically binding to the variable location text properties resolved by the reverse-geocoding runtime engine or incoming database payload models.

6. Missing Transactional Activity Append
The Issue: Completed trips failing to persist, write, or display inside the Passenger's Recent Activity screen upon processing the terminal fare collection.

The Description: The trip wrap-up state handler failing to successfully trigger or await the completion mutation pipeline targeting the backend microservice repository.

7. Layout Constraints & Canvas Dropouts
The Issue: The entire top map viewport rendering as a blank white container across driver flow transitions instead of loading visual geographic vector tiles.

The Description: A layout constraint collapse occurring within nested columns or flex boxes that strips the hardware-accelerated map view engine of its spatial boundary context.

📈 Section 2: Precise Suggestions for Antigravity
Enforce Loopback Bridging for Emulator Environments: Configure the network layer to target the dedicated Android host bridge loopback IP (10.0.2.2) or execute global adb reverse tcp:PORT tcp:PORT terminal scripts for every active microservice port during local emulator testing execution.

Implement an Imperative Hardware Location Guard: Deploy an up-front guard routine before initializing location tracking or loading map instances. This engine must check the system-level location service status via your location plugin; if service availability returns false, it must explicitly call the native service request framework to slide up the system settings toggle overlay automatically.

Bind Visual Text Layouts to Actual Resolved Address Data: Refactor the pick-up and drop-off text nodes to completely drop raw string blocks like "Current Location". They must directly display the dynamic properties containing the actual text address string derived from your geocoded network layer or your unified data model.

Implement a Type-Safe Global Parser: Introduce a strict parsing layer designed to safely intercept and convert numeric fields (int, double, num, and String) with reliable null-aware fallbacks. This isolates the application runtime from dropping threads due to Null is not a subtype of type 'num' mismatches.

Enforce Strict Route Instance Passing: Update the routing state machinery to explicitly forward the complete runtime entity record via the router state's structural argument payloads instead of falling back on unlinked static placeholders midway through active trips.

Transition from Polling to Stream Connections: Replace resource-intensive high-frequency periodic REST polling loops with a structured streaming connection architecture (such as WebSockets or Server-Sent Events). This handles real-time coordination without hammering the database or backends.

Isolate and Constrain the Map Viewport: Wrap hardware-accelerated map widgets tightly within strict layout constraint structures, such as a sizing builder or an aspect-ratio frame, ensuring nested UI changes do not cause height metric collapses.

Unified Network Error Boundary Interceptors: Attach a strict global error interceptor to the application network client to cleanly handle low-level loopback connectivity drops before they can bubble up to break visual layout widgets.
