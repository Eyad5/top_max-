# Salary Endpoint Audit - Testing Guide

## Purpose
Identify exactly why Postman shows salary data but the Flutter app doesn't by comparing the SAME job across different API endpoints.

## APK Location
`g:\top_maxtesttt\build\app\outputs\flutter-apk\app-release.apk` (24.7MB)

---

## Test Procedure

### STEP 1: Identify Target Jobs
1. Open the app and note **2-3 specific job IDs and titles** from Home page
2. Example: "Secretary" job #1, "Laravel Developer" job #25, etc.
3. Write down: Job ID, Job Title, whether salary is visible in app

### STEP 2: Test Each Endpoint Flow

#### Test 2A: Home Page (uses `/mobile/home`)
1. Open app fresh → Home page loads
2. **Collect logs** showing:
   ```
   📡 ENDPOINT: GET /mobile/home
   💰 SALARY AUDIT: /mobile/home endpoint
      Job #1 "Secretary" from /mobile/home:
         - formatted_salary: ???
         - min_salary: ???
         - max_salary: ???
   ```

#### Test 2B: Job Details (uses `/user/jobs/{id}`)
1. Tap on a specific job to open details
2. **Collect logs** showing:
   ```
   💰 SALARY AUDIT: GET /user/jobs/1 endpoint
      Job #1 "Secretary" from /user/jobs/{id}:
         - formatted_salary: ???
         - min_salary: ???
         - max_salary: ???
   ```

#### Test 2C: Search Results (uses `/home/search`)
1. Search for a keyword (e.g., "secretary" or "remote")
2. **Collect logs** showing:
   ```
   📡 ENDPOINT: GET /home/search?keyword=secretary
   💰 SALARY AUDIT: /home/search endpoint
      Job #1 "Secretary" from /home/search:
         - formatted_salary: ???
         - min_salary: ???
         - max_salary: ???
   ```

#### Test 2D: Saved Items (uses `/user/saved-items`)
1. Save a job from Home page
2. Navigate to Bookmarks tab
3. **Collect logs** showing:
   ```
   📡 ENDPOINT: GET /user/saved-items?type=jobs
   💰 SALARY AUDIT: /user/saved-items?type=jobs endpoint
      Job #1 "Secretary" from /user/saved-items:
         - formatted_salary: ???
         - min_salary: ???
         - max_salary: ???
   ```

### STEP 3: Compare with Postman
1. Open Postman collection: `lib/postman/Himma Test.postman_collection.json`
2. Find the endpoint that showed "Secretary" job with salary
3. Note: endpoint URL, parameters, response structure
4. **Compare salary fields** from Postman vs app logs

---

## What to Look For

### Scenario 1: Backend Inconsistency
**Symptom:** Same job ID has DIFFERENT salary data across endpoints

**Example:**
```
/mobile/home:        formatted_salary: "From AED  to  / month" (BROKEN)
/user/jobs/1:        formatted_salary: "From AED 3000 / month" (VALID)
/user/saved-items:   formatted_salary: "From AED 3000 / month" (VALID)
```

**Diagnosis:** Backend returns inconsistent data. `/mobile/home` has worse quality data.

**Fix:** App should hydrate salary from `/user/jobs/{id}` for Home page cards (already doing this for some jobs, may need to expand)

---

### Scenario 2: Endpoint Mismatch
**Symptom:** App uses endpoint A, but Postman uses endpoint B with better data

**Example:**
```
App uses:     /mobile/home (has no salary)
Postman uses: /user/jobs?search=secretary (has salary)
```

**Diagnosis:** App using wrong endpoint or wrong parameters

**Fix:** Switch to the endpoint Postman uses, or use same parameters

---

### Scenario 3: All Endpoints Return Null
**Symptom:** ALL endpoints return null/malformed salary for the same job

**Example:**
```
/mobile/home:        formatted_salary: null, min: null, max: null
/user/jobs/1:        formatted_salary: null, min: null, max: null
/user/saved-items:   formatted_salary: null, min: null, max: null
```

**Diagnosis:** Backend has no salary data for this specific job (data quality issue on backend)

**Fix:** Cannot fix in frontend. Backend needs to populate salary data.

---

### Scenario 4: Postman Shows Salary, All App Endpoints Don't
**Symptom:** Postman request shows salary, but ALL app endpoints return null

**Diagnosis:**
- Postman using different auth token with different permissions?
- Postman using different endpoint version?
- Postman using query params that filter to jobs WITH salary?

**Fix:** Identify exact Postman endpoint/params and replicate in app

---

## Search Chips Audit

### Keyword-Based Chips (Current Implementation)
```dart
'Remote Jobs'    → keyword=remote         ✅ Works
'AI'             → keyword=AI             ✅ Works
'Data Entry'     → keyword=data entry     ⚠️  Backend may have 0 matches
```

### Filter-Based Chips (NOT IMPLEMENTED - Should Use)
```dart
'Blindness'      → Should use: disability=<id>  (NOT keyword=blindness)
'Deafness'       → Should use: disability=<id>  (NOT keyword=deafness)
'Urgent Hiring'  → Could use: is_urgent=true    (NOT keyword=urgent)
```

### Search Endpoint Supports These Filters
From `lib/features/home/data/home_api.dart`:
- `keyword` (string)
- `disability` (int) ← **Disability chips should use this**
- `location_type` (string) - e.g., "remote", "hybrid", "onsite"
- `salary_min` (num)
- `salary_max` (num)
- `job_type` (string)
- `experience` (string)

### Recommended Chip Fixes
1. **"Remote Jobs"** → Use `location_type=remote` instead of `keyword=remote`
2. **"Blindness"/"Deafness"** → Use `disability=<id>` (need to find correct IDs from backend)
3. **"Urgent Hiring"** → Check if backend supports `is_urgent` filter

---

## Expected Log Output Format

When you run the tests, you should see logs like this for comparison:

```
🔄 TAB SWITCH: 1 → 0

📡 ENDPOINT: GET /mobile/home
💰 SALARY AUDIT: /mobile/home endpoint
   Job #1 "Secretary" from /mobile/home:
      - formatted_salary: From AED  to  / month
      - min_salary: null
      - max_salary: null
      - salary_to_be_discussed: false
      - company_name: Tech Corp

🔵 HomeBloc: Emitted HomeLoaded state

💰 Hydrating salaries for 3 jobs (max 10 to avoid rate limits)...

💰 SALARY AUDIT: GET /user/jobs/1 endpoint
   Job #1 "Secretary" from /user/jobs/{id}:
      - formatted_salary: From AED 3000 / month
      - min_salary: 3000
      - max_salary: 5000
      - salary_to_be_discussed: false
      - company_name: Tech Corp

⚠️ JobModel #1: Rejected malformed formatted_salary: "From AED  to  / month"

💰 Job #1 salary resolution:
   - formattedSalary: NULL (rejected by validation)
   - minSalary: NULL, maxSalary: NULL
   - salaryToBeDiscussed: false
   - RESULT: NULL (no valid salary data)
```

**Analysis of Above:**
- `/mobile/home` returns MALFORMED `formatted_salary` + null min/max
- `/user/jobs/1` returns VALID `formatted_salary` + valid min/max
- **DIAGNOSIS: Backend inconsistency** - `/mobile/home` has worse data quality
- **FIX NEEDED:** Salary hydration from `/user/jobs/{id}` is already working, but malformed data from `/mobile/home` should be ignored earlier

---

## Next Steps After Testing

1. **Share the complete logs** showing salary data for the same job across all 4 endpoints
2. **Identify the pattern** using scenarios above
3. **Compare with Postman** - which endpoint did Postman use? What were the exact parameters?
4. **I will implement the precise fix** based on the exact discrepancy found

---

## Quick Reference: Log Markers to Search For

Search your logs for these markers:
- `📡 ENDPOINT:` - Shows which endpoint was called
- `💰 SALARY AUDIT:` - Shows raw salary fields from that endpoint
- `⚠️ JobModel #X: Rejected malformed` - Shows when frontend rejects bad data
- `💰 Job #X salary resolution:` - Shows final computed salary value
- `🔄 TAB SWITCH:` - Shows tab navigation that triggers endpoints
