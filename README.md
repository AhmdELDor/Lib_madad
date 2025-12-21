# Library Manager (LibManager) - Project Plan

## Overview
A simple, classic library management system built with Flutter.
**Goal:** Manage books, clients, borrowing transactions (with donations), events, and view statistics.
**Language:** Arabic (Primary).
**Platform:** Android, iOS, Windows, Web.

## Tech Stack & Packages
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** `provider` (Simple & Practical)
- **Database:** `isar` (Fast, NoSQL, easy to use) or `sqflite`
- **Localization:** `flutter_localizations`, `intl`
- **Fonts:** `google_fonts` (Cairo or Tajawal for Arabic)
- **Charts:** `fl_chart` (For statistics)
- **Image Picker:** `image_picker` (To pick images from gallery)
- **Notifications:** `flutter_local_notifications` (For deadline alerts)
- **Icons:** `font_awesome_flutter` (Optional, for more icons)

## Folder Structure
```
lib/
├── main.dart           # Entry point
├── models/             # Data models (Book, Client, Borrowing, Event)
├── screens/            # UI Screens (Home, Books, Clients, etc.)
├── widgets/            # Reusable UI components (Sidebar, Cards, etc.)
├── services/           # Database and Logic services
├── providers/          # State management providers
└── utils/              # Constants, Themes, Helpers
```

## Development Phases

### Phase 1: Setup & Configuration
1.  **Clean Up:** Remove default counter app code.
2.  **Dependencies:** Add the packages listed above to `pubspec.yaml`.
3.  **Localization:** Configure the app for Arabic (`ar`) locale and RTL support.
4.  **Theme:** Set up a global theme using a classic Arabic font (e.g., 'Cairo').
5.  **Assets:** Create an `assets/images` folder for placeholders.

### Phase 2: Database & Models
1.  **Models:** Create Dart classes for:
    - `Book`: `id`, `title`, `author`, `genre`, `imagePath`, `description`, `isAvailable`, `borrowCount`.
    - `Client`: `id`, `name`, `phone`, `borrowCount`.
    - `Borrowing`: `id`, `bookId`, `clientId`, `borrowDate`, `deadline`, `donationAmount`, `isReturned`.
    - `Event`: `id`, `title`, `imagePaths` (List of strings), `date`, `description`.
    - `Feedback`: `id`, `bookId`, `comment`, `rating`.
2.  **Database Service:** Initialize the local database (Isar/Hive/Sqflite). Implement CRUD (Create, Read, Update, Delete) operations for all models.

### Phase 3: UI Skeleton & Navigation
1.  **Sidebar (Drawer):** Create a reusable sidebar widget with links to:
    - Home (Statistics)
    - Books
    - Clients
    - Borrowings
    - Events
2.  **Layout:** Create a `BaseScreen` or `MainLayout` that includes the AppBar and Sidebar.

### Phase 4: Book Management
1.  **Book List:** Display books in a grid or list. Show image, title, and availability status.
2.  **Add/Edit Book:** Create a form to input book details.
    - Use `image_picker` to select an image from the gallery.
    - Store the *path* of the image in the database.
3.  **Filters:** Add a filter bar to filter books by Genre or Category.

### Phase 5: Client Management
1.  **Client List:** Display a simple list of clients.
2.  **Add/Edit Client:** Form for Name and Phone number.

### Phase 6: Borrowing System
1.  **New Borrowing:**
    - Select a Client (Dropdown or Search).
    - Select a Book (Only available books).
    - Pick a Deadline date.
    - Enter Donation amount (Optional).
2.  **Logic:** When a book is borrowed, update its status to `isAvailable = false`.
3.  **Active Borrowings:** List of books currently out. Highlight overdue items.
4.  **Return Book:** Button to mark a borrowing as returned. Update book status to `isAvailable = true`.
5.  **Alerts:** Schedule a local notification for the deadline.

### Phase 7: Events
1.  **Event List:** Show upcoming events with images.
2.  **Add Event:** Simple form to add event info and image.

### Phase 8: Statistics (Home Page)
1.  **Summary Cards:** Total Books, Active Borrowings, Total Clients, Total Donations.
2.  **Charts:**
    - Pie Chart: Books by Genre.
    - Bar Chart: Borrowings per month.

### Phase 9: Final Polish
1.  **Validation:** Ensure all inputs are valid (e.g., phone numbers, required fields).
2.  **Testing:** Test the full flow (Add Book -> Add Client -> Borrow -> Return).
3.  **Release:** Build the app for production.
