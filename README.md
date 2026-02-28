# Group Name: Chill Guys  

## Project Overview  
ParcelKita is an AI-powered campus parcel management system designed to eliminate manual logging, ophan parcels ans unfair penalties through dual layered AI integration and real time cloud synchronization.  
## Problem Statement  
![Problems](images/Problems.png)  
With the rapid growth of e-commerce, university parcel collection systems remain largely manual and fragmented.  
### Across multiple Malaysian universities:  
- Notifications are sent via WhatsApp (individual or group-based)  
- Students must manually check Shopee or Lazada for delivery updates  
- Some parcels arrive without phone numbers  
- Students often use nicknames when ordering online  
- Late pickup penalties are applied even when notifications are missed  
### As a result:  
- Parcels become unmatched (“orphan parcels”)  
- Storage spaces become congested  
- Administrative workload increases  
- Students experience frustration and perceive the system as unfair  
- There is currently no centralized intelligent system to automate parcel logging, recipient matching, and notification delivery.

## Our Solution  
ParcelKita is a dual-sided AI-powered parcel management platform connecting Admins and Students.  
It:  
- Uses AI to extract structured data from shipping labels  
- Enables students to pre-register tracking numbers (Fast Track Claim)  
- Automatically matches anonymous parcels  
- Sends personalized AI notifications  
- Tracks overdue charges transparently  
- Synchronizes all updates in real-time

ParcelKita transforms manual campus logistics into a centralized intelligent system.  

## AI Integration  
ParcelKita meaningfully integrates Google AI technologies:  
- Google Gemini 2.5 Flash  
- Google ML Kit 
- Gemini Text Generation  
AI directly automates data extraction, matching, and communication.

## SDG Alignment  
### SDG 9 – Industry, Innovation & Infrastructure  
Digitizes and modernizes campus logistics infrastructure  
### SDG 11 – Sustainable Cities & Communities  
Reduces storage congestion and improves fairness in shared campus living  
### SDG 12 – Responsible Consumption  
Minimizes returned parcels and reduces manual paper logging  

## Google Technology Utilization  
### Google Gemini 2.5 Flash (Cloud AI)  
- We used Gemini Vision to convert messy, unstructured parcel labels into structured JSON data  
#### Effect:  
- Eliminates manual data entry  
- Reduces logging errors  
- Automatically extracts tracking ID, name, and phone number  
  
### Google ML Kit(On-device AI Fallback)  
We implemented ML Kit Text Recognition as an offline fallback  
#### Effect:  
- Scanning continues even without internet  
- Ensures operational resilience  
- Prevents workflow interruption  

### Firebase Cloud Firestore   
We used Firestore for real-time synchronization between admin AI scans, student Fast Track registrations and parcel status updates  
#### Effect:  
- Instant parcel matching  
- No delay between admin and student view  
- Eliminates orphan parcels  

### Flutter (Cross-Platform Google Technology)  
Built entirely using Google Flutter  
#### Effect:  
- Single codebase for Web + Android  
- Consistent UI for Admin & Students  
- Rapid prototyping and scalability  

## System Architecture  
ParcelKita follows a Dual-Layer AI Architecture:  
#### Cloud Layer  
- Gemini Vision for Primary OCR  
- Gemini Text for Notification generation  
#### Edge Layer  
- ML Kit OCR fallback  
#### Database Layer   
- Firebase Authentication  
- Firebase Cloud Firestore  
#### Presentation Layer     
- Flutter Admin Interface  
- Flutter Student Interface  

This architecture ensures reliability, scalability, and real-time synchronization  

## Key Features    
1. Dual AI OCR System - Cloud AI + Edge fallback for reliable scanning  
2. Fast Track Claim - Students pre-register tracking numbers. Even if nicknames were used, parcels are matched instantly  
3. Smart AI Notifications - Gemini generates contextual, personalized alerts  
4. Overdue Transparency - System automatically tracks deadlines, calculates overdue fees and displays fee breakdown clearly  

Both Admins and Students see the same synchronized data.  

## How it works?  
1. Student pre-registers tracking number(for students who use nicknames on their parcel)  
2. Parcel arrives at campus  
3. Admin scans label  
4. Gemini extracts structured data  
5. Firestore matches tracking number  
6. Student receives AI-generated notification  
7. Status updates in real-time  
   
Everything connects within seconds  

## User Testing & Iteration   
We conducted testing with: 3 university students and 1 admin staff  
#### Feedback 1: Students felt penalties were unfair when no notification was received  
Improvement: Added transparent overdue breakdown and notification timestamp  

#### Feedback 2: Staff struggled when parcels arrived without phone numbers   
Improvement: Implemented Fast Track Claim system  

#### Feedback 3: Manual logging consumed too much time  
Improvement: Adopted AI-based structured extraction  

## Technical Challenges & Solutions  
#### Challenge 1: Traditional OCR returned unstructured text blocks  
Solution: Shifted to Gemini Vision for structured JSON extraction  
#### Challenge 2: ML Kit incompatible with Web platform  
Solution: Implemented platform checks and fallback logic to Gemini Cloud for Web builds  

## Success Metrics  
The system tracks performance using measurable indicators:  
- Average parcel logging time (seconds per scan)  
- Matching latency (time from scan to user match)  
- Percentage of unmatched parcels  
- Overdue rate  
- Notification delivery timestamp logs  

Data is collected through Firebase event tracking.  

## Expected Impact  
Based on initial prototype testing, ParcelKita aims to:    
- Reduce unmatched parcels by up to 60%  
- Improve logging efficiency by approximately 50%  
- Decrease penalty-related disputes by around 40%  
- Improve overall parcel flow transparency    

## Scalability and Future Roadmap 
Future improvements may include:  
#### Public parcel search for unmatched parcels  
To further reduce unmatched parcels, ParcelKita’s current architecture allows the introduction of a Public Parcel Search feature. In scenarios where parcels cannot be automatically matched (e.g., missing phone numbers or nickname usage), unmatched entries can be stored in a searchable list. Students would be able to search and claim their parcels using tracking IDs.This extension enhances fairness and ensures parcels remain retrievable without significantly altering the existing system structure. 
#### Smart locker systems  
ParcelKita’s scanning and notification workflow allows potential integration with smart locker systems. By linking parcel status updates with locker assignment logic, the system could support automated pickup processes where students receive secure access codes upon parcel arrival.This extension builds upon the existing real-time notification and tracking structure without requiring fundamental redesign.  
#### Parcel analytics dashboard for admins  
Using Firebase event logs, ParcelKita can be extended to provide basic analytics for administrative insights.  
This may include metrics such as: Average pickup duration， frequency of overdue parcels and peak parcel arrival periods  
Such analytics could assist staff in improving storage planning and operational efficiency.

## Project Setup  
1. Clone & Install Dependencies  
Run the following step by step  
> git clone https://github.com/gweezini/KitaHack2026.git  

> cd KitaHack2026  

> flutter pub get  

2. Firebase Configuration  
ParcelKita relies on Firebase Authentication and Cloud Firestore.  
Steps:  
   i. Create a Firebase project  
   ii. Enable Firestore Database (Test mode for development)  
   iii. Enable Authentication (Email/Password)  
   iv. Run:  
> flutterfire configure  

This will generate the required firebase_options.dart file.

3. Gemini API Key Setup  
To ensure API security, ParcelKita uses flutter_dotenv.  
Create a .env file in the project root:  
> GEMINI_API_KEY=YOUR_GEMINI_API_KEY

The .env file is excluded via .gitignore to prevent key exposure.

4. Run the App  
> flutter run

Platform Notes:  
ParcelKita implements a dual-layer AI architecture:  
- Google Gemini (Cloud AI)  
- Google ML Kit (On-device fallback)  

⚠ ML Kit Text Recognition relies on native Android/iOS binaries and is not supported on Flutter Web.  
When running on Web, the system automatically bypasses ML Kit and relies entirely on Gemini.  
To experience the offline OCR fallback, please run the app on a physical Android.  

## Demo Video:  
YouTube Link:  https://youtu.be/17MouTStAXI   

The demo showcases:  
- Admin scanning workflow  
- AI extraction  
- Fast Track matching  
- Student notification  
- Real-time status update  
