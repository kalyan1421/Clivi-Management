# Clivi-Management
Clivi Management is a role-based civil construction project management app built with Flutter + Supabase, enabling Admins and Site Managers to manage projects, track material stock (Received vs Cons# Clivi Management 🏗️📊  
A role-based **Civil Construction Project Management App** built using **Flutter + Supabase**, designed to manage construction projects, site operations, staff, material stock, bills, and reports — all in one place.

---

## 🚀 Overview  
**Clivi Management** helps construction teams digitize day-to-day site activities by providing a centralized system for:

✅ Project creation & assignment  
✅ Site staff management (Admin / Site Manager / Engineer)  
✅ Material tracking (Received ✅ / Consumption ✅)  
✅ Auto-calculated remaining stock  
✅ Vendor-based material logs  
✅ Bill raising & payment tracking  
✅ Reports & dashboards for real-time monitoring  

---

## 👥 User Roles & Permissions  

### 🔑 1) Super Admin  
- Manage complete system access  
- Control admins & global settings  
- View all projects and reports  

### 🛠️ 2) Admin  
- Create projects  
- Assign projects to Site Managers / Engineers  
- Add & manage staff  
- Approve bills & manage documents  
- Generate reports (stock, vendor, site usage)

### 🏗️ 3) Site Manager / Site Engineer  
- View assigned projects  
- Update daily site stock  
- Add material **Received** and **Consumption**  
- Raise bills (Advance / Part Bill / Full Bill)  
- Upload site documents (photos, invoices, work updates)

---

## ✅ Key Features  

### 📁 Project Management  
- Create and manage multiple projects  
- Assign projects to staff  
- Store project info, location, and status

### 👷 Staff Management  
- Admin creates Site Manager / Engineer accounts  
- Role-based dashboards and permissions  
- Staff assignment and tracking

### 🧱 Material Stock Management  
Track construction materials like:  
- Cement 🧱  
- Steel 🏗️  
- Sand  
- Bricks  
- Other site materials  

✅ Two core options:  
- **Received Stock** → materials delivered to site  
- **Consumption Stock** → daily usage by site team  

📌 System automatically calculates:  
**Remaining Stock = Total Received - Total Consumed**

### 🧾 Bills & Payment Workflow  
- Site Engineer raises bill request  
- Bill type options:  
  ✅ Advance  
  ✅ Part Bill  
  ✅ Full Bill  
- Office Accountant/Admin can close bills when paid

### 📊 Reports & Dashboard  
Generate real-time insights like:  
- Total Stock vs Used Stock vs Remaining Stock  
- Vendor-wise material reports  
- Project-wise usage summary  
- Staff performance tracking  
- Bill status reports

### 📂 Document Management  
- Project document upload support  
- Admin can create folders inside a project (Blueprint segregation)  
- Example folders:  
  - Blueprints  
  - Site Photos  
  - Invoices  
  - Contracts  
  - Work Progress Docs

---

## 🧱 Tech Stack  

### 📱 Frontend  
- **Flutter (Dart)**
- Riverpod (state management)  
- GoRouter (navigation + guards)

### 🔥 Backend  
- **Supabase**
  - Auth (Email/OTP)  
  - Postgres Database  
  - RLS policies (role-based security)  
  - Storage (documents + bills + images)

---

## 📂 Project Folder Structure (Clean Architecture)

lib/
├── main.dart  
├── core/  
│   ├── config/  
│   ├── router/  
│   ├── theme/  
│   ├── widgets/  
│   ├── utils/  
│   └── errors/  
├── features/  
│   ├── auth/  
│   │   ├── data/  
│   │   ├── domain/  
│   │   └── presentation/  
│   ├── projects/  
│   ├── materials/  
│   ├── bills/  
│   ├── reports/  
│   ├── staff/  
│   └── profile/  

---

## ⚙️ Setup & Installation  

### ✅ 1. Clone Repository
```bash
git clone https://github.com/<your-username>/Clivi-Management.git
cd Clivi-Management
```

### ✅ 2. Install Dependencies
```bash
flutter pub get
```

### ✅ 3. Add Supabase Credentials  
Create a file:  
`lib/core/config/env.dart`

```dart
class Env {
  static const supabaseUrl = "YOUR_SUPABASE_URL";
  static const supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
}
```

### ✅ 4. Run the App
```bash
flutter run
```

---

## 🔐 Security (Supabase RLS)  
This project uses **Row Level Security (RLS)** to ensure:

✅ Admin can access only their projects  
✅ Site Manager can access only assigned projects  
✅ Staff cannot edit restricted modules  
✅ Storage access controlled by role  

---

## 📌 Roadmap (Next Updates)
✅ Notifications for material updates & bill approvals  
✅ Offline mode for site updates  
✅ Auto-generated PDF reports  
✅ Multi-site project support  
✅ Attendance & daily work log module  
✅ Expense & budget tracking  

---

## 📸 Screenshots  
📌 (Add your app UI screenshots here)

---

## 🤝 Contributing  
Pull requests are welcome!  
For major changes, please open an issue first.

---

## 📄 License  
This project is private/proprietary for Clivi usage.  
(You can update license later)

---

## 👨‍💻 Developed By  
**Kalyan Kumar Bedugam**  
Flutter Developer | Full Stack | Supabase | Firebase | AI Appsumption), handle vendors &amp; staff, and generate site reports in real-time.
