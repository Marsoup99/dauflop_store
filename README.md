Dauflop Store
Dauflop Store is a Flutter-based application designed for managing a small store. It includes features for inventory management, handling sales, and generating reports. The application is built with a client-facing side for customers and an admin-facing side for store owners.

Getting Started
This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

Lab: Write your first Flutter app

Cookbook: Useful Flutter samples

For help getting started with Flutter development, view the
online documentation, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Features
The application is divided into two main parts: a public store for customers and an admin panel for store management.

Public Store
The public store allows customers to browse products, add items to their cart, and place orders. Key features include:

Product display: Shows a grid of available products with images, brand, category, color, and price.

Search and filter: Customers can search for products and filter them by category.

Shopping cart: A fully functional shopping cart that allows users to add, remove, and update the quantity of items.

Checkout process: A comprehensive checkout process that includes entering shipping information and selecting a payment method.

Payment options: Supports both Cash on Delivery (COD) with a deposit and VietQR for full payment.

Admin Panel
The admin panel provides a suite of tools for the store owner to manage their inventory and sales. The main features are:

Inventory management: Allows adding, editing, and deleting items from the store's inventory.

Incoming orders: A dedicated screen to view and manage new orders placed by customers.

Pending sales: A screen to track and manage orders that are awaiting confirmation or payment.

Sales summary: Provides a monthly report of sales performance, including total revenue, cost of goods sold, and profit.

Localization: The admin panel supports Vietnamese language for a better user experience.

Dependencies
The project uses several dependencies to achieve its functionality. The main dependencies are:

firebase_core, cloud_firestore, firebase_storage, firebase_auth: For backend services like database, storage, and authentication.

image_picker: To allow users to pick images from their gallery.

month_year_picker: For selecting a month and year in the sales summary screen.

google_sign_in: For authenticating users with their Google account.

url_launcher: To open URLs, specifically for the VietQR payment method.

crypto, intl, convert: For various utility functions like hashing, date formatting, and data conversion.

Project Structure
The project follows a standard Flutter project structure, with the main application logic located in the lib directory. The lib directory is further organized into the following subdirectories:

screens: Contains the main screens of the application, such as the inventory screen, add item screen, and summary screen.

widgets: Contains reusable widgets that are used across multiple screens.

models: Contains the data models for the application, such as Item, CartItem, and PendingSale.

services: Contains the business logic for the application, such as the CartService.

localizations: Contains the localization files for the application.

theme: Contains the theme data for the application.
