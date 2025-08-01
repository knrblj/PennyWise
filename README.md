# 💸 KB Expense Tracker

A beautiful, glassy-designed Flutter application for tracking daily financial transactions with backend analytics integration.

## ✨ Features

- **🌟 Glassy Modern UI**: Beautiful frosted glass design with blur effects
- **📱 Cross-platform**: Runs on Linux, macOS, iOS, and Android
- **💰 Transaction Management**: Add, view, and categorize income/expenses
- **📊 Real-time Analytics**: Automatic sync with external analytics backend
- **🎨 Google Fonts**: Beautiful Poppins font throughout the app
- **🌙 Dark/Light Theme**: Automatic system theme support
- **📈 Balance Tracking**: Real-time balance, income, and expense summaries

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- For Linux: `flutter config --enable-linux-desktop`
- For macOS: Xcode installed
- For iOS: Xcode and iOS Simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd kb_track_expense
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoint (Optional)**
   - Edit `lib/constants/app_constants.dart`
   - Replace the placeholder API URL with your actual analytics backend
   - Add your API key or authentication token

4. **Run the application**
   ```bash
   # Linux
   flutter run -d linux
   
   # macOS
   flutter run -d macos
   
   # iOS Simulator
   flutter run -d ios
   
   # Android
   flutter run -d android
   ```

## 🏗️ Project Structure

```
lib/
├── main.dart                      # App entry point with theme configuration
├── constants/
│   └── app_constants.dart         # API endpoints and app constants
├── models/
│   └── transaction_model.dart     # Data model for transactions
├── screens/
│   └── home_screen.dart          # Main application screen
├── services/
│   └── api_service.dart          # Backend API integration
└── widgets/
    ├── add_transaction_modal.dart # Modal for adding new transactions
    ├── glass_card.dart           # Reusable glass effect widget
    └── transaction_tile.dart      # Individual transaction display
```

## 🎨 Design Features

### Glassy UI Elements
- **BackdropFilter**: Creates beautiful blur effects
- **Rounded Corners**: 16-20px radius for modern look
- **Gradient Backgrounds**: Subtle color transitions
- **Semi-transparent Cards**: Glass-like appearance
- **Smooth Animations**: Scale and fade transitions

### Typography
- **Google Fonts**: Poppins font family
- **Consistent Sizing**: 12px to 24px hierarchy
- **Weight Variations**: 400 to 700 for emphasis

## 📊 Analytics Integration

The app automatically syncs transaction data to your configured analytics backend:

### API Payload Format
```json
{
  "id": "unique_transaction_id",
  "amount": 250.0,
  "type": "debit",
  "category": "Food",
  "note": "Lunch at cafe",
  "date": "2025-08-01T12:30:00Z"
}
```

### Configuration
1. Update `ApiConstants.baseUrl` in `app_constants.dart`
2. Add your API key to `ApiConstants.apiKey`
3. Configure authentication if needed

## 🎯 Transaction Categories

- 🍔 Food
- 🚗 Transport  
- 🛍️ Shopping
- 🎬 Entertainment
- 📄 Bills
- 🏠 Rent
- 💰 Salary
- 📈 Investment
- 🏥 Health
- 🎓 Education
- 📦 Other

## 🛠️ Future Enhancements

- [ ] **Local Database**: Hive or SQLite integration
- [ ] **Data Export**: CSV/PDF export functionality
- [ ] **Charts & Insights**: Visual analytics with fl_chart
- [ ] **Budget Limits**: Set and track spending limits
- [ ] **Authentication**: PIN or biometric security
- [ ] **Filters**: Date range and category filtering
- [ ] **Notifications**: Budget alerts and reminders

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| 🐧 Linux | ✅ Ready | Primary development platform |
| 🍎 macOS | ✅ Ready | Desktop optimized |
| 📱 iOS | ✅ Ready | Mobile optimized |
| 🤖 Android | ✅ Ready | Mobile optimized |
| 🌐 Web | 🔄 Future | Planned enhancement |

## 🎨 Screenshots

*Add screenshots here once the app is running*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Google Fonts** for beautiful typography
- **Material Design** for design inspiration

---

**Built with ❤️ and Flutter**
