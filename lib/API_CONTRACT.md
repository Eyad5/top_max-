# API CONTRACT — From Postman

Base URL:
{{base_url}}

Authentication:
Bearer Token required for all /user/* endpoints.

---

## HOME

GET /mobile/home

GET /home/search

---

## SAVED ITEMS

GET /user/saved-items?type=jobs
GET /user/saved-items?type=courses

Response:
{
  "status": "success",
  "message": "Saved items fetched successfully.",
  "status_code": "SC-200",
  "data": {
    "data": [
      {
        "id": 1,
        "job_title": "Transportation Attendant",
        "company_id": 1,
        "company_logo": null,
        "company_name": "Florence Melendez",
        "job_description": "Ex quaerat vero magnam autem. Laborum quaerat aut beatae est quisquam placeat quod. Placeat consequuntur est quisquam dolorem cum cum laborum tempora.",
        "location_priority": "remote",
        "status": "opened",
        "app_status": null,
        "min_salary": 3000,
        "max_salary": 6000,
        "job_type": "part-time",
        "office_location": "Bridgetburgh",
        "type": "job",
        "is_multiple_hires": false,
        "is_urgent": false,
        "is_featured": true,
        "is_saved": true,
        "created_at": "2025-06-20 08:10:26",
        "active_since": "Active 1 week ago",
        "formatted_salary": "From AED 3000 / month"
      }
    ],
    "pagination": {
      "total": 1,
      "per_page": 12,
      "current_page": 1,
      "last_page": 1,
      "from": 1,
      "to": 1,
      "has_more_pages": false
    }
  }
}

---

## JOBS

GET /jobs
GET /user/jobs/{id}
POST /user/jobs/{id}/toggle-save

Response samples:

curl --location -g '{{base_url}}user/jobs?page=1'


{
  "status": "success",
  "message": "Jobs fetched successfully.",
  "status_code": "SC-200",
  "data": [
    {
      "id": 6,
      "company_id": 1,
      "job_title": "Senior Laravel Developer",
      "job_description": "Responsible for building and maintaining web applications.",
      "responsibilities": "Write clean, scalable code.",
      "requirements": "3+ years Laravel experience.",
      "qualifications": "BSc Computer Science",
      "benefits": "BSc Computer Science",
      "min_salary": 2000,
      "max_salary": 10000,
      "salary_to_be_discussed": false,
      "experience_level": "junior",
      "education": "Bachelor's degree or higher.",
      "job_type": "part-time",
      "location_priority": "hybrid",
      "office_location": "Cairo, Egypt",
      "is_multiple_hires": true,
      "is_urgent": true,
      "status": "opened",
      "created_at": "2025-05-06 11:18:10"
    },
    {
      "id": 5,
      "company_id": 1,
      "job_title": "junior Laravel Developer",
      "job_description": "Responsible for building and maintaining web applications.",
      "responsibilities": "Write clean, scalable code.",
      "requirements": "3+ years Laravel experience.",
      "qualifications": "BSc Computer Science",
      "benefits": "BSc Computer Science",
      "min_salary": 5000,
      "max_salary": 11000,
      "salary_to_be_discussed": false,
      "experience_level": "mid-senior",
      "education": "Bachelor's degree or higher.",
      "job_type": "part-time",
      "location_priority": "remote",
      "office_location": "Cairo, Egypt",
      "is_multiple_hires": true,
      "is_urgent": true,
      "status": "opened",
      "created_at": "2025-05-06 11:17:57"
    },
    {
      "id": 4,
      "company_id": 1,
      "job_title": "junior Laravel Developer",
      "job_description": "Responsible for building and maintaining web applications.",
      "responsibilities": "Write clean, scalable code.",
      "requirements": "3+ years Laravel experience.",
      "qualifications": "BSc Computer Science",
      "benefits": "BSc Computer Science",
      "min_salary": 5000,
      "max_salary": 11000,
      "salary_to_be_discussed": false,
      "experience_level": "mid-senior",
      "education": "Bachelor's degree or higher.",
      "job_type": "part-time",
      "location_priority": "remote",
      "office_location": "Cairo, Egypt",
      "is_multiple_hires": true,
      "is_urgent": true,
      "status": "opened",
      "created_at": "2025-05-06 11:17:01"
    },
    {
      "id": 3,
      "company_id": 1,
      "job_title": "junior Laravel Developer",
      "job_description": "Responsible for building and maintaining web applications.",
      "responsibilities": "Write clean, scalable code.",
      "requirements": "3+ years Laravel experience.",
      "qualifications": "BSc Computer Science",
      "benefits": "BSc Computer Science",
      "min_salary": 5000,
      "max_salary": 11000,
      "salary_to_be_discussed": false,
      "experience_level": "mid-senior",
      "education": "Bachelor's degree or higher.",
      "job_type": "part-time",
      "location_priority": "remote",
      "office_location": "Cairo, Egypt",
      "is_multiple_hires": true,
      "is_urgent": true,
      "status": "opened",
      "created_at": "2025-05-06 11:16:55"
    },
    {
      "id": 2,
      "company_id": 1,
      "job_title": "junior Laravel Developer",
      "job_description": "Responsible for building and maintaining web applications.",
      "responsibilities": "Write clean, scalable code.",
      "requirements": "3+ years Laravel experience.",
      "qualifications": "BSc Computer Science",
      "benefits": "BSc Computer Science",
      "min_salary": 2000,
      "max_salary": 10000,
      "salary_to_be_discussed": false,
      "experience_level": "junior",
      "education": "Bachelor's degree or higher.",
      "job_type": "part-time",
      "location_priority": "hybrid",
      "office_location": "Cairo, Egypt",
      "is_multiple_hires": true,
      "is_urgent": true,
      "status": "opened",
      "created_at": "2025-05-06 11:15:48"
    }
  ]
}





curl --location -g '{{base_url}}user/jobs/1' \
--header 'Accept: application/json'



{
  "status": "success",
  "message": "Job details fetched successfully.",
  "status_code": "SC-200",
  "data": {
    "id": 1,
    "company_id": 1,
    "company": {
      "id": 1,
      "name": "Florence Melendez",
      "logo": null
    },
    "job_title": "Transportation Attendant",
    "job_description": "Ex quaerat vero magnam autem. Laborum quaerat aut beatae est quisquam placeat quod. Placeat consequuntur est quisquam dolorem cum cum laborum tempora.",
    "responsibilities": "Distinctio vel quasi veniam velit dolores esse dolore. Facere veritatis quisquam laboriosam a provident sint. Qui iusto aut excepturi iusto.",
    "requirements": "Quaerat voluptas minima eveniet illum et quos soluta.",
    "qualifications": "Recusandae repellat ullam asperiores facilis aut omnis.",
    "benefits": "Nulla et omnis quia odit in.",
    "min_salary": 3000,
    "max_salary": 6000,
    "salary_to_be_discussed": false,
    "experience_level": "senior",
    "years_of_experience": 0,
    "city_id": null,
    "education": "bachelor",
    "job_type": "part-time",
    "location_priority": "remote",
    "office_location": "Bridgetburgh",
    "is_multiple_hires": false,
    "is_urgent": false,
    "is_saved": true,
    "disability_other": null,
    "status": "opened",
    "has_applied": false,
    "created_at": "2025-06-20 08:10:26"
  }
}



curl --location -g --request POST '{{base_url}}user/jobs/1/toggle-save' \
--header 'Accept: application/json'

{
  "status": "success",
  "message": "Job saved successfully.",
  "status_code": "SC-200"
}




---

## COURSES

GET /user/courses
GET /user/courses/{id}
POST /user/courses/{id}/save

Response samples:


curl --location -g '{{base_url}}user/courses?category_id=3&level=beginner&type=online&has_certificate=1&page=1&search=Mastering' \
--header 'Accept: application/json'



{
  "status": "success",
  "message": "Courses fetched successfully.",
  "status_code": "SC-200",
  "data": {
    "courses": [
      {
        "id": 16,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": null,
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 15,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": null,
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 14,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "http://127.0.0.1:8000/storage/20/681b5768d8c47.jpg",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 13,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "http://127.0.0.1:8000/storage/19/681b56afcdb37.jpg",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 12,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "http://127.0.0.1:8000/storage/18/681b55f958370.jpg",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 11,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "http://127.0.0.1:8000/storage/17/681b559c4dd58.PNG",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 10,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "805601da-ca4d-42bd-883c-f6bbe39d0d3b",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 9,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": "7b500f87-3eaf-41ac-91db-46d80722d258",
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 8,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": null,
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      },
      {
        "id": 7,
        "title": "Mastering UI/UX Design",
        "description": "Comprehensive course in UI/UX with hands-on projects.",
        "featured_image": null,
        "price": "0.00",
        "is_free": 1,
        "company_id": 1,
        "status": "active"
      }
    ],
    "links": {
      "first": "http://127.0.0.1:8000/api/user/courses?page=1",
      "last": "http://127.0.0.1:8000/api/user/courses?page=2",
      "prev": null,
      "next": "http://127.0.0.1:8000/api/user/courses?page=2"
    },
    "meta": {
      "current_page": 1,
      "from": 1,
      "last_page": 2,
      "path": "http://127.0.0.1:8000/api/user/courses",
      "per_page": 10,
      "to": 10,
      "total": 14
    }
  }
}





curl --location -g '{{base_url}}user/courses/19'




{
  "status": "success",
  "message": "Course details fetched successfully.",
  "status_code": "SC-200",
  "data": {
    "id": 19,
    "title": "Mastering UI/UX Design",
    "description": "Comprehensive course in UI/UX with hands-on projects.",
    "highlights": [
      "User Interface Design basics",
      "Figma basics",
      "Figma advance",
      "Figma prototype and animations",
      "Introduction to user experience design",
      "How to do research work",
      "How to optimize the design",
      "How to deliver the project"
    ],
    "featured_image": "http://127.0.0.1:8000/storage/4/681c8a2719887.jpg",
    "course_category": "Customer Service",
    "price": "0.00",
    "is_free": 1,
    "level": "beginner",
    "has_certificate": 1,
    "start_date": "2025-06-01",
    "start_time": "10:00:00",
    "available_seats": 50,
    "type": "online",
    "location": null,
    "company_id": 1,
    "status": "active"
  }
}




curl --location -g --request POST '{{base_url}}user/courses/12/save' \
--header 'Accept: application/json'



{
  "status": "success",
  "message": "Course saved successfully.",
  "status_code": "SC-200"
}

---

## LOCATION

GET /location/countries
GET /location/countries/{id}/cities
GET /location/cities/{id}?return_default_cities=true




curl --location -g '{{base_url}}location/countries' \
--header 'Accept: application/json'



{
  "status": "success",
  "message": "Countries fetched successfully.",
  "status_code": "SC-200",
  "data": [
    {
      "id": 1,
      "name": "Saudi Arabia",
      "iso": "SA",
      "code": "+966",
      "flag": "http://127.0.0.1:8000/storage/96/flag_SA.png"
    },
    {
      "id": 2,
      "name": "Egypt",
      "iso": "EG",
      "code": "+20",
      "flag": "http://127.0.0.1:8000/storage/90/flag_EG.png"
    },
    {
      "id": 3,
      "name": "United Arab Emirates",
      "iso": "AE",
      "code": "+971",
      "flag": "http://127.0.0.1:8000/storage/91/flag_AE.png"
    },
    {
      "id": 4,
      "name": "Jordan",
      "iso": "JO",
      "code": "+962",
      "flag": "http://127.0.0.1:8000/storage/97/flag_JO.png"
    },
    {
      "id": 5,
      "name": "Morocco",
      "iso": "MA",
      "code": "+212",
      "flag": "http://127.0.0.1:8000/storage/98/flag_MA.png"
    },
    {
      "id": 6,
      "name": "Qatar",
      "iso": "QA",
      "code": "+974",
      "flag": "http://127.0.0.1:8000/storage/99/flag_QA.png"
    },
    {
      "id": 7,
      "name": "Kuwait",
      "iso": "KW",
      "code": "+965",
      "flag": "http://127.0.0.1:8000/storage/100/flag_KW.png"
    },
    {
      "id": 8,
      "name": "Bahrain",
      "iso": "BH",
      "code": "+973",
      "flag": "http://127.0.0.1:8000/storage/101/flag_BH.png"
    },
    {
      "id": 9,
      "name": "Oman",
      "iso": "OM",
      "code": "+968",
      "flag": "http://127.0.0.1:8000/storage/102/flag_OM.png"
    },
    {
      "id": 10,
      "name": "Syria",
      "iso": "SY",
      "code": "+963",
      "flag": "http://127.0.0.1:8000/storage/92/flag_SY.png"
    },
    {
      "id": 11,
      "name": "Palestine",
      "iso": "PS",
      "code": "+970",
      "flag": "http://127.0.0.1:8000/storage/93/flag_PS.png"
    },
    {
      "id": 12,
      "name": "India",
      "iso": "IN",
      "code": "+91",
      "flag": "http://127.0.0.1:8000/storage/94/flag_IN.png"
    },
    {
      "id": 13,
      "name": "Pakistan",
      "iso": "PK",
      "code": "+92",
      "flag": "http://127.0.0.1:8000/storage/95/flag_PK.png"
    }
  ]
}





curl --location -g '{{base_url}}location/countries/2/cities' \
--header 'Accept: application/json'





{
  "status": "success",
  "message": "Cities fetched successfully.",
  "status_code": "SC-200",
  "data": [
    {
      "id": 1,
      "name": "Cairo"
    },
    {
      "id": 2,
      "name": "Alexandria"
    },
    {
      "id": 3,
      "name": "Giza"
    }
  ]
}





curl --location -g '{{base_url}}location/cities/2?return_default_cities=true' \
--header 'Accept: application/json'






{
  "status": "success",
  "message": "Cities fetched successfully.",
  "status_code": "SC-200",
  "data": [
    {
      "id": 7,
      "name": "Dubai"
    },
    {
      "id": 8,
      "name": "Abu Dhabi"
    },
    {
      "id": 9,
      "name": "Sharjah"
    }
  ]
}