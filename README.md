# BarTracker App

BarTracker is a crowdsourced app that provides real-time information on bar occupancy and wait times. It combines user-generated data and location-based insights to help users decide where to go for the best experience.

---

## Features

- **Crowdsourced Data**: Users can submit occupancy levels and line wait times.
- **Location-Based Occupancy**: Gets users near specific bars (If location access is allowed)
- **User-Friendly Interface**: Simple and intuitive design for easy data submission.

---

## Installation

### Prerequisites
1. Python 3.x
2. PostgreSQL
3. [Redis](https://redis.io/) (for Celery)
4. Virtual environment tools like `venv`
## Setup

1. **Clone the repository:**
    ```bash
   git clone https://github.com/lhakso/bar_tracker.git
   cd bar_tracker
2. **Set up Python venv**
    ```bash
   python3 -m venv bar_tracker_venv
   source bar_tracker_venv/bin/activate  # On Linux/Mac
   bar_tracker_venv\Scripts\activate


3. **Install dependencies:**
    ```bash
    pip install -r requirements.txt

4. **Set up PostgreSQL:**
- Create a database and user.
- Configure `.env` with your database credentials.


5. **Run migrations:**
    ```bash
    python manage.py makemigrations
    python manage.py migrate

6. **Set up Redis:**
    Install Redis on your system (instructions for installation).

    Start the Redis server:
    ```bash
    redis-server

7. **Set up Celery:**
    Start the Celery Worker
    
    ```bash
    celery -A bar_tracker worker --loglevel=info

8. **Set up Celery Beat (for periodic tasks):**
    Start the beat scheduler

    ```bash
    Set up Celery Beat (for periodic tasks):

9. **Start the development server:**
    ```bash
    python manage.py runserver


## License
This project is licensed under the MIT License.

## Contact
Name: Luke Hakso   
Email: luke.c.hakso@gmail.com  
GitHub: lhakso
