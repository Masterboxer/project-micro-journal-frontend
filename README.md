```
flutter run -d web-server --web-port 5000
```

# Project Micro Journal — MVP Pages & Tracker

> Minimal, 1-week MVP pages list (Flutter frontend + Go backend + Postgres).

---

## Overview

Goal: Fast, test-ready MVP for Chennai wards that gives users instant local utility: detect ward from GPS → show councillor → let user submit a simple issue → view local feed and trending.

---

# Pages

## 1. Splash / Permission Prompt

**Purpose:** Intro + request location permission.  
**Description:** Show name/logo, one-line pitch, ask for location permission. On allow → detect ward. On deny → manual location entry.  
**Backend:** None.

---

## 2. Onboarding / Quick Tour (optional)

**Purpose:** One-screen explanation of features.  
**Backend:** None.

---

## 3. Ward / Councillor Screen (Home)

**Purpose:** Core screen showing detected Ward & Councillor.  
**Description:** Ward number, Zone, Councillor card (name, phone, email). CTAs: “Raise Issue”, “See Local Feed”, “What To Do”.  
**Backend:** `GET /api/wards/lookup?lat={}&lng={}`

---

## 4. Manual Ward Selection

**Purpose:** Let user correct ward.  
**Description:** Search by address or select from nearby wards.  
**Backend:**

- `GET /api/wards/nearby?lat=&lng=`
- `GET /api/wards/search?q=`

---

## 5. Issue Category / What-to-do Guide

**Purpose:** Give categories + quick guidance.  
**Description:** 6 categories: Roads, Garbage, Water, Electricity, Streetlights, Others. Static text + templates.  
**Backend:** None (static JSON).

---

## 6. Submit Issue

**Purpose:** Minimal issue reporting.  
**Description:** Category, description (required), optional contact. Auto tag ward & zone.  
**Backend:** `POST /api/issues`

---

## 7. Local Issue Feed

**Purpose:** Show recent issues in the ward.  
**Description:** List view, newest first.  
**Backend:** `GET /api/issues?ward_id=&limit=&offset=`

---

## 8. Trending / Summary

**Purpose:** Mini dashboard of top categories this week.  
**Backend:** `GET /api/issues/summary?ward_id=&period=7d`

---

## 9. Councillor Detail

**Purpose:** Expanded councillor info.  
**Description:** Contacts, office info, email template.  
**Backend:** `GET /api/councillors/{ward_id}`

---

## 10. Settings / About / Privacy

**Purpose:** Ward change, privacy text, version info.  
**Backend:** None.

---

## 11. Error / Empty States

**Purpose:** Graceful handling for missing location, network errors, empty feed.

---

## 12. (Optional) Simple Admin / Inbox Page

**Purpose:** Internal page for reviewing issues.  
**Backend:**

- `GET /admin/issues`
- `POST /admin/issues/{id}/resolve`

---

# Navigation Flow

1. Splash → Ward Screen
2. Ward Screen → Submit Issue → Success → Feed
3. Ward Screen → Feed
4. Ward Screen → What-to-do → templates
5. Settings → change ward

---

# Backend API Summary

## The Main Tables

1. Wards
2. Councillors
3. Issues
