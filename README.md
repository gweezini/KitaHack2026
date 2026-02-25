# Kitahack2026  
# Group Name: Chill Guys  

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
#### Firebase Cloud Firestore   
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
#### Improvement: Added transparent overdue breakdown and notification timestamp  

#### Feedback 2: Staff struggled when parcels arrived without phone numbers   
#### Improvement: Implemented Fast Track Claim system  

#### Feedback 3: Manual logging consumed too much time  
#### Improvement: Adopted AI-based structured extraction  

## Technical Challenges & Solutions  
#### Challenge 1: Traditional OCR returned unstructured text blocks  
#### Solution: Shifted to Gemini Vision for structured JSON extraction  
#### Challenge 2: ML Kit incompatible with Web platform  
#### Solution: Implemented platform checks and fallback logic to Gemini Cloud for Web builds  

## Success Metrics  
Estimated improvements based on testing:  
- 60% reduction in unmatched parcels  
- 50% faster logging time  
- 40% reduction in disputes over penalties  
  
Firebase event tracking logs: Scan timestamps, matching speed and notification delivery events  

