Lib/Src/Core/
├── Constants/
│   ├── ApiEndpoints.dart               # Base URLs & endpoint strings
│   ├── AppConstants.dart               # Timeouts, default map settings
│   └── StorageKeys.dart                # Secure storage key identifiers
├── Errors/
│   ├── Exceptions.dart                 # Data source exceptions
│   ├── Failures.dart                   # Equatable failures for BLoC/Domain
│   └── ErrorHandler.dart               # DioException -> Failure translator
├── Network/
│   ├── ApiClient.dart                  # High-level HTTP contract
│   ├── DioClient.dart                  # Configured Dio instance
│   └── Interceptors/
│       ├── AuthInterceptor.dart        # Bearer token injection
│       ├── LoggingInterceptor.dart     # Terminal debug logging
│       └── RetryInterceptor.dart       # Network retry handler
├── Services/                           # System/Hardware services
│   ├── AudioService.dart               # Voice prompts & alert tones
│   └── NotificationService.dart        # Local background notification triggers
├── Storage/
│   ├── LocalStorage.dart               # SharedPreferences wrapper
│   └── SecureStorage.dart              # Encrypted token storage
├── Theme/
│   ├── AppColors.dart                  # Color palette
│   ├── AppTypography.dart              # Text themes
│   └── AppTheme.dart                   # Dark/Light ThemeData definitions
├── Utils/
│   ├── AppLogger.dart                  # Log printer wrapper
│   ├── DateFormatter.dart              # PH time zone & relative date helpers
│   ├── NumberFormatter.dart            # Currency (₱) & distance formatters
│   └── Validators.dart                 # Input validation helpers
└── Extensions/
    ├── ContextExtensions.dart          # SnackBar, theme, & screen size extensions
    ├── StringExtensions.dart           # String manipulations
    └── NumExtensions.dart              # Padding & layout size extensions
