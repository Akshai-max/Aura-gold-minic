# Aura Gold

Production-ready Flutter (Mobile App) and FastAPI (Backend Service) platform for **Aura Gold**, featuring enterprise-grade gold trading workflows.

---

## Architecture & System Flow

Phase 3 implements the complete, end-to-end **Gold Trading Workflow** (Buy Gold, Sell Gold, Orders History, Timeline Tracing, Simulated Razorpay checkout sheets, and Admin settings).

### 1. Buy Gold & Razorpay Checkout Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Mobile App
    participant BE as FastAPI Backend
    participant DB as DB (PostgreSQL)
    participant RP as Razorpay Simulated Sheet

    User->>BE: POST /buy (amount or grams)
    Note over BE: Retrieves current price & margins<br/>Calculates GST (3%) + fees (2%)
    BE->>DB: Save Order (status: PENDING_PAYMENT)
    BE-->>User: Return Order Detail & checkout tokens
    User->>RP: Open Simulated Payment Overlay
    RP->>RP: Form Inputs (UPI, Card Formatters) & Validate
    RP-->>User: Simulated Outcome (Success / Cancel)
    alt Success
        User->>BE: POST /payments/verify (signature = mock_signature)
        Note over BE: Validates payment signature
        BE->>DB: Add Payment (status: SUCCESS)
        BE->>DB: Create Trade (BUY)
        BE->>DB: Update Wallet (gold_balance, available_gold, total_invested)
        BE->>DB: Update LedgerTransaction (BUY, status: COMPLETED)
        BE->>DB: Mark Order COMPLETED
        BE-->>User: Return verified COMPLETED Order
        User->>User: Route to PaymentStatusScreen (Success checkmark)
    else Cancel / Failure
        User->>User: Route to PaymentStatusScreen (Error cross)
    end
```

### 2. Sell Gold FIFO PnL Cost-Basis Flow

```mermaid
flowchart TD
    A[Start: POST /sell] --> B{Enforce Trading Status?}
    B -->|Disabled| C[Error: Trading disabled]
    B -->|Enabled| D{Verify Available Gold Balance?}
    D -->|Insufficient| E[Error: Insufficient available gold]
    D -->|Sufficient| F[Fetch Completed BUY Orders with remaining_quantity > 0 ordered by oldest first]
    F --> G[Initialize cost_basis = 0, remaining_to_sell = quantity_to_sell]
    G --> H{remaining_to_sell > 0?}
    H -->|No| K[Create Completed SELL Order & Trade]
    H -->|Yes| I[Select oldest active BUY order]
    I --> J[deduct = min remaining_quantity, remaining_to_sell]
    J --> L[cost_basis += deduct * buy_order.price]
    L --> M[Update buy_order.remaining_quantity]
    M --> N[remaining_to_sell -= deduct]
    N --> H
    K --> O[Deduct gold_balance & available_gold from Wallet]
    O --> P[wallet.total_invested -= cost_basis]
    P --> Q[Create LedgerTransaction COMPLETED]
    Q --> R[Return Order & payout balance adjustment]
```

---

## Directory Structure

```text
ags/
├── lib/                             # Flutter Mobile App
│   ├── core/                        # Network client, theme, responsive widgets
│   ├── routes/                      # GoRouter router definitions
│   └── features/
│       ├── buy_gold/                # Input forms, margins breakdown, review invoices
│       ├── sell_gold/               # Balance checking, sell max shortcut
│       ├── orders/                  # Filtered orders history lists
│       ├── payments/                # Razorpay checkout sheet overlay, status feedback
│       ├── settings/                # Admin margins and daily limits config
│       └── transaction_details/     # Vertical progress status timeline trace
├── backend/                         # FastAPI Backend
│   ├── app/
│   │   ├── models/trading.py        # SQLAlchemy Order, Payment, Trade, Settings tables
│   │   ├── schemas/trading.py       # Pydantic validation schema payloads
│   │   ├── services/trading_service.py # FIFO engines and payment verifications
│   │   └── api/v1/                  # API routers
│   └── tests/                       # Pytest unit testing suite
└── test/                            # Flutter testing suite (unit, widget, integration)
```

---

## How to Run & Verify

### 1. Running the FastAPI Backend

Make sure Python 3.12+ and PostgreSQL are installed.

```powershell
# Navigate and setup environment
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install requirements
pip install -e .[dev]

# Apply alembic migrations and database seeds
alembic upgrade head
python -m app.seed

# Start backend server
uvicorn app.main:app --reload
```

- Swagger docs will be hosted at: `http://localhost:8000/docs`
- Default Admin Account: `admin@auragold.com` / `Admin@123`
- Default User Account: `user@auragold.com` / `User@123`

### 2. Running the Flutter App

Ensure Flutter 3.x SDK is configured.

```powershell
# Get packages
flutter pub get

# Launch on developer emulator/device
flutter run
```

---

## Testing & Verification Suite

Automated pipelines cover backend business models, calculator functions, input states validations, and end-to-end integration workflows.

### 1. Executing Backend API & Engine Tests (Python)

Verifies GST rounding, daily cap resets, and the correctness of the FIFO profit calculations.

```powershell
cd backend
.venv\Scripts\pytest
```

### 2. Executing Frontend Tests (Flutter)

Compiles and triggers unit, widget, and integration test specifications.

```powershell
# Run the entire test suite (43 assertions)
flutter test

# Run individual specifications
flutter test test/buy_sell_unit_test.dart
flutter test test/trading_widgets_test.dart
flutter test test/trading_integration_test.dart
```
