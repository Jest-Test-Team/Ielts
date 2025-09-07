# 📋 IELTS Repository: File Naming Convention Guide

_This guide ensures consistent, predictable file naming to prevent 404 errors and improve repository organization._

---

## **Core Naming Convention**

### **Format: `YYYY-MM-DD-[TaskType]-[Topic].md`**

**Examples:**

- `2025-08-26-WT2-Housing-vs-Parks.md`
- `2025-09-01-WT1-Tourist-Enquiries.md`
- `2025-09-15-Speaking-Part2-Favorite-Place.md`
- `2025-09-20-Listening-Section3-Academic-Lecture.md`

---

## **Detailed Rules**

### **1. Date Format**

- **Always use:** `YYYY-MM-DD`
- **Never use:** `YYYY_MM_DD`, `DD-MM-YYYY`, `MM/DD/YYYY`
- **Examples:**
  - ✅ `2025-08-26`
  - ❌ `2025_08_26`, `26-08-2025`, `08/26/2025`

### **2. Task Type Abbreviations**

- **Writing Task 1:** `WT1`
- **Writing Task 2:** `WT2`
- **Speaking Part 1:** `SP1`
- **Speaking Part 2:** `SP2`
- **Speaking Part 3:** `SP3`
- **Listening Section 1:** `LS1`
- **Listening Section 2:** `LS2`
- **Listening Section 3:** `LS3`
- **Listening Section 4:** `LS4`
- **Reading Passage 1:** `RP1`
- **Reading Passage 2:** `RP2`
- **Reading Passage 3:** `RP3`

### **3. Topic Formatting**

- **Use hyphens:** `Housing-vs-Parks`
- **No spaces:** `Tourist-Enquiries`
- **No underscores:** `Academic-Lecture`
- **Capitalize first letter:** `Favorite-Place`
- **Keep it descriptive:** `Problem-Solution-Topics`

### **4. Special Cases**

#### **Strategy Files**

- **Format:** `[skill]-[type]-[description].md`
- **Examples:**
  - `writing-task1-structure-guide.md`
  - `speaking-part2-topic-cards.md`
  - `listening-section3-academic-vocabulary.md`

#### **Practice Logs**

- **Format:** `YYYY-MM-DD-[TaskType]-[Topic]-practice.md`
- **Examples:**
  - `2025-08-26-WT2-Housing-vs-Parks-practice.md`
  - `2025-09-01-WT1-Tourist-Enquiries-practice.md`

#### **Error Analysis Files**

- **Format:** `YYYY-MM-DD-[TaskType]-[Topic]-errors.md`
- **Examples:**
  - `2025-08-26-WT2-Housing-vs-Parks-errors.md`
  - `2025-09-01-WT1-Tourist-Enquiries-errors.md`

---

## **File Organization Structure**

```
03_Writing/
├── 0_pre-flight_checklist.md
├── Task_1/
│   ├── 1_strategy/
│   │   ├── structure-and-pipeline.md
│   │   ├── comparison-phrases.md
│   │   └── vocabulary-master-sheet.md
│   └── 2_practice_log/
│       ├── 2025-08-26-WT1-Tourist-Enquiries-practice.md
│       └── 2025-08-27-WT1-Sales-Data-practice.md
└── Task_2/
    ├── 1_strategy/
    │   ├── essay-structures.md
    │   ├── argument-bank.md
    │   └── useful-vocabularies-phrases.md
    └── 2_practice_log/
        ├── 2025-08-26-WT2-Housing-vs-Parks-practice.md
        └── 2025-08-27-WT2-Technology-Education-practice.md

04_Speaking/
├── active_recall_drills.md
├── practice_logs/
│   ├── 2025-09-01-SP1-Introduction-practice.md
│   ├── 2025-09-02-SP2-Favorite-Place-practice.md
│   └── 2025-09-03-SP3-Education-Discussion-practice.md
└── topic_practice_log.md
```

---

## **Common Mistakes to Avoid**

### **❌ Don't Use:**

- **Spaces:** `Mix Charts.md` → `mix-charts.md`
- **Underscores:** `2025_08_26_map.md` → `2025-08-26-map.md`
- **Mixed case:** `Bar-Chart-Analysis.md` → `bar-chart-analysis.md`
- **Inconsistent dates:** `2025_08_26` → `2025-08-26`
- **Vague names:** `practice.md` → `2025-08-26-WT2-Housing-vs-Parks-practice.md`

### **✅ Do Use:**

- **Hyphens:** `housing-vs-parks.md`
- **Consistent dates:** `2025-08-26`
- **Descriptive names:** `tourist-enquiries-practice.md`
- **Task type indicators:** `WT2`, `SP2`, `LS3`

---

## **URL Generation Rules**

### **How Jekyll Converts Filenames to URLs**

**Input:** `2025-08-26-WT2-Housing-vs-Parks-practice.md`
**Output:** `https://ielts-prepare.dennisleehappy.org/03_Writing/Task_2/2_practice_log/2025-08-26-WT2-Housing-vs-Parks-practice.html`

**Key Points:**

- `.md` becomes `.html`
- Hyphens remain as hyphens
- Spaces become `%20` (causing 404 errors)
- Underscores remain as underscores

---

## **Quality Checklist**

Before creating any new file, ask:

1. **Date:** Is the date in `YYYY-MM-DD` format?
2. **Task Type:** Is the task type clearly indicated?
3. **Topic:** Is the topic descriptive and clear?
4. **Hyphens:** Are hyphens used instead of spaces?
5. **Lowercase:** Are all letters lowercase?
6. **Consistent:** Does it follow the established pattern?

---

## **Examples by Category**

### **Writing Practice Logs**

- `2025-08-26-WT1-Tourist-Enquiries-practice.md`
- `2025-08-27-WT1-Sales-Data-practice.md`
- `2025-08-28-WT2-Technology-Education-practice.md`
- `2025-08-29-WT2-Environment-Protection-practice.md`

### **Speaking Practice Logs**

- `2025-09-01-SP1-Introduction-practice.md`
- `2025-09-02-SP2-Favorite-Place-practice.md`
- `2025-09-03-SP3-Education-Discussion-practice.md`

### **Strategy Files**

- `writing-task1-structure-guide.md`
- `speaking-part2-topic-cards.md`
- `listening-section3-academic-vocabulary.md`

### **Error Analysis Files**

- `2025-08-26-WT2-Housing-vs-Parks-errors.md`
- `2025-09-01-WT1-Tourist-Enquiries-errors.md`

---

## **Implementation Steps**

1. **Review existing files** and rename any that don't follow this convention
2. **Use this guide** when creating new files
3. **Check URLs** after creating files to ensure they work
4. **Update links** in index.md and other files when renaming
5. **Commit changes** regularly to maintain consistency

---

**🎯 Remember: Consistent naming prevents 404 errors and makes your repository professional and easy to navigate.**
