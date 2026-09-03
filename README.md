# Crop Trade Management

A Flutter-based management application designed to organize agricultural crop trading operations and simplify the financial workflow between crop owners and the person responsible for selling their crop.

The application brings customers, suppliers, transactions, history, debts, and financial information into one organized workflow, with a focus on practical day-to-day business management.

---

## Overview

Crop Trade Management was built to solve a practical business problem: managing agricultural crop sales and the financial relationships connected to those sales.

Instead of relying on scattered records, the application provides a structured way to manage business data, follow transactions, review historical activity, and keep track of financial obligations.

---

## Key Features

* **Customer Management**

  * Organize customer information.
  * View customer details.
  * Keep customer-related records in one place.

* **Supplier Management**

  * Manage supplier information.
  * View supplier details.
  * Organize supplier-related records.

* **Transaction Management**

  * Create and manage business transactions.
  * Maintain transaction data through dedicated models and services.
  * Keep transaction operations organized within the application.

* **History & Daily Activity**

  * Review historical business activity.
  * View detailed information for individual days.
  * Search historical records by day.
  * Review current debt-related information.

* **Dashboard & Home**

  * Central dashboard for accessing the application's main functions.
  * Organized navigation between business management areas.

* **Financial Management**

  * Support for tracking debts and financial obligations related to business activity.
  * Structured organization of financial records and transaction history.

* **PDF Support**

  * Dedicated PDF-related functionality within the application's core layer.

* **Local Data Management**

  * Application data is organized through dedicated storage and service layers.

---

## Technical Stack

| Area                     | Technology                               |
| ------------------------ | ---------------------------------------- |
| Framework                | Flutter                                  |
| Language                 | Dart                                     |
| Application Architecture | Feature-based structure                  |
| Data Handling            | Models & Services                        |
| Storage                  | Local application storage                |
| Reporting                | PDF functionality                        |
| Platforms                | Android, iOS, Web, Windows, macOS, Linux |
| Development Tools        | Git, GitHub, Visual Studio Code          |

---

## Project Structure

The project follows a feature-oriented structure to keep business functionality separated and maintainable.

```text
lib/
├── core/
│   ├── constants/
│   ├── pdf/
│   ├── services/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── customers/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── views/
│   │
│   ├── history/
│   │   ├── day_full_details_screen.dart
│   │   ├── history_home_screen.dart
│   │   ├── search_day_screen.dart
│   │   └── today_debts_screen.dart
│   │
│   ├── home/
│   │   ├── dashboard_screen.dart
│   │   └── home_screen.dart
│   │
│   ├── reports/
│   │
│   ├── suppliers/
│   │   ├── controllers/
│   │   ├── models/
│   │   └── views/
│   │
│   └── transactions/
│       ├── models/
│       │   └── transaction_model.dart
│       └── services/
│           └── transaction_service.dart
│
├── storage/
└── main.dart
```

---

## Architecture Approach

The application uses a **feature-based organization** combined with separation between UI, models, controllers, services, and shared core functionality.

This structure helps:

* Keep related business functionality together.
* Separate presentation from data and business operations.
* Make the codebase easier to navigate and maintain.
* Support future expansion of individual features.
* Keep shared functionality inside the `core` layer.

---

## Supported Platforms

The Flutter project includes platform targets for:

* Android
* iOS
* Web
* Windows
* macOS
* Linux

The primary application workflow is designed around practical business management and can be extended as the system evolves.

---

## Getting Started

### Prerequisites

Make sure you have:

* Flutter SDK installed
* Dart SDK available through Flutter
* Android Studio or Visual Studio Code
* Git

### Installation

Clone the repository:

```bash
git clone git@github.com:SaqrAminAL-Dhafree/crop-trade-management.git
```

Move into the project directory:

```bash
cd crop-trade-management
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

---

## Development Notes

This project is maintained as a practical software application and is structured to allow additional business features, improvements, and refinements to be introduced without restructuring the entire codebase.

---

## Project Goals

The main goals of the application are to:

1. Organize agricultural crop trading operations.
2. Reduce dependence on scattered manual records.
3. Centralize customer, supplier, and transaction information.
4. Make historical activity easier to review.
5. Improve visibility into debts and financial obligations.
6. Provide a maintainable foundation for future development.

---

## Author

**Saqr Ameen Al-Dhafree**

Full Stack Developer | Flutter & Dart | Backend Development

* LinkedIn: [https://www.linkedin.com/in/saqraldhafree](https://www.linkedin.com/in/saqraldhafree)
* GitHub: [https://github.com/SaqrAminAL-Dhafree](https://github.com/SaqrAminAL-Dhafree)

---

## License

This project is provided as a portfolio and demonstration project.
