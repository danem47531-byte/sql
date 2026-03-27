# 🛒 Flipkart Logistics & Delivery Analysis — SQL Project

![SQL](https://img.shields.io/badge/Language-SQL-blue) ![MySQL](https://img.shields.io/badge/Database-MySQL-orange) ![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

## 📌 Project Overview

This project performs an end-to-end SQL-based analysis of Flipkart's logistics and delivery operations. Using a relational database with five core tables — **Orders, Shipments, Routes, Warehouses, and Delivery Agents** — the project covers data cleaning, performance analysis, route optimization, and agent evaluation to uncover operational bottlenecks and improve delivery efficiency.

---

## 🗄️ Database Schema

The project uses the following five tables:

| Table | Description |
|---|---|
| `orders` | Order details including dates, warehouse, route, and delivery status |
| `shipment` | Shipment tracking with checkpoint times, delay minutes, and delay reasons |
| `routes` | Route details including distance, travel time, traffic delay, start/end locations |
| `warehouses` | Warehouse info including processing capacity and average processing time |
| `deliveryagents` | Agent details including speed, on-time delivery percentage, and assigned route |

---

## 🧹 Task 1 — Data Cleaning & Preprocessing

- Identified and checked for **duplicate Order IDs** using `GROUP BY` and `HAVING COUNT(*) > 1`
- Replaced **null/zero delay minutes** with the calculated average delay
- Standardized all **date columns** to `YYYY-MM-DD` format using `STR_TO_DATE()` and `ALTER TABLE ... MODIFY`
- Validated delivery dates — flagged any records where `Actual_Delivery_Date < Order_Date` using a **generated column** and a `CHECK` constraint

---

## 📊 Task 2 — Delivery Delay Analysis

- Calculated **delivery delay in days** per order using `DATEDIFF(Actual_Delivery_Date, Expected_Delivery_Date)`
- Identified the **Top 10 most delayed routes** based on average combined travel and traffic delay time
- Used **window functions** (`DENSE_RANK() OVER PARTITION BY`) to rank orders by delay within each warehouse

---

## 🗺️ Task 3 — Route Performance & Optimization

- Calculated per-route metrics:
  - **Average delivery time** (converted from minutes to days/hours/minutes)
  - **Average traffic delay** across all routes
  - **Distance-to-time efficiency ratio** (`Distance_KM / Average_Travel_Time_Min`)
- Identified the **3 worst-performing routes** by efficiency ratio
- Used **CTEs and JOINs** to find routes with **>20% delayed shipments**
- **Key Finding:** Routes `RT_08` (Pune) and `RT_15` (Hyderabad) were identified as primary bottlenecks with average delays of ~90 and ~87 minutes respectively, flagged for route re-optimization

---

## 🏭 Task 4 — Warehouse Performance Analysis

- Found the **Top 3 warehouses** with the highest average processing time
- Calculated **total vs. delayed shipment counts** per warehouse with delay percentage
- Used **chained CTEs** to find bottleneck warehouses where processing time exceeded the global average
- **Ranked all warehouses** by on-time delivery percentage using `RANK() OVER (ORDER BY ...)`

---

## 🚴 Task 5 — Delivery Agent Evaluation

- Ranked all agents by **on-time delivery percentage** using `DENSE_RANK()`
- Identified agents in the **bottom 80th percentile** (on-time % below threshold) using `PERCENT_RANK()`
- Compared **average speed of Top 5 vs. Bottom 5 agents** using subqueries and `UNION ALL`
- **Recommendations for low performers:**
  - Route familiarization and time-management training
  - Mentorship pairing with top-performing agents
  - Equitable redistribution of high-difficulty routes
  - Regular performance check-ins and feedback loops

---

## 📦 Task 6 — Shipment Tracking & Delay Reasons

- Listed the **last checkpoint and time** for each order from the shipment table
- Found the **most common delay reasons** (ranked by frequency using `RANK() OVER`)
- Identified orders with **more than 2 delayed checkpoints** using `HAVING COUNT(...) > 2`

---

## 📈 Task 7 — KPI Dashboard & Summary Metrics

- **Average Delivery Delay per Region** (grouped by Start and End Location)
- **Overall On-Time Delivery Percentage** calculated as:
  ```
  On-Time % = (Total On-Time Deliveries / Total Deliveries) × 100
  ```
- **Average Traffic Delay per Route** using `AVG(Traffic_Delay_Min)`

---

## 🛠️ SQL Concepts & Techniques Used

| Concept | Usage |
|---|---|
| DDL / DML | `CREATE`, `ALTER`, `UPDATE`, `INSERT` |
| Aggregate Functions | `COUNT`, `SUM`, `AVG`, `ROUND` |
| Date Functions | `STR_TO_DATE`, `DATEDIFF`, `DATETIME` |
| Window Functions | `RANK()`, `DENSE_RANK()`, `PERCENT_RANK()` with `PARTITION BY` |
| CTEs | Multi-level `WITH` clauses for bottleneck analysis |
| Subqueries | Nested queries for Top 5 vs Bottom 5 agent comparison |
| JOINs | `INNER JOIN`, `LEFT JOIN`, `CROSS JOIN` |
| Constraints | `CHECK` constraints, Generated Columns |
| CASE Statements | Conditional logic for validation and classification |
| UNION ALL | Combining result sets for comparative analysis |

---

## 📁 Project Files

```
📦 SQL Project
 ┣ 📄 Flipkart SQL Scripting.sql       # All SQL queries across 7 tasks
 ┗ 📊 SQL Power Point Presentation.pptx  # Project presentation slides
```

---

## 🚀 How to Run

1. Open **MySQL Workbench** or any MySQL-compatible client
2. Run `CREATE DATABASE flipkart;` and `USE flipkart;`
3. Import the five data tables: `orders`, `shipment`, `routes`, `warehouses`, `deliveryagents`
4. Execute the queries in `Flipkart SQL Scripting.sql` sequentially from Task 1 to Task 7

---

## 💡 Key Insights

- **Pune (RT_08) and Hyderabad (RT_15)** routes have the worst delay metrics and need urgent attention
- Several **warehouses exceed the global average processing time**, creating downstream delivery bottlenecks
- A subset of delivery agents falls below acceptable on-time thresholds and would benefit from targeted training
- The overall **on-time delivery percentage** and per-region delay patterns provide a clear picture for operational decision-making

---

## 👤 Author

### Tridev Pal
📍 Calcutta, West Bengal, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?logo=linkedin)](https://www.linkedin.com/in/tridev-pal-74575a379/)

> Feel free to connect or raise issues via GitHub if you have suggestions or improvements!
