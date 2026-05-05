# Backend Setup Guide for Deep Linking - Lorry App

## Overview
This guide explains how to set up the Django backend to support deep linking for the Lorry mobile app. When users share trip links, the backend needs to:
1. Serve the `assetlinks.json` file for Android App Links verification
2. Handle the share URL and redirect to the app or show a web page

---

## Part 1: Setup Android App Links Verification

### Step 1: Create assetlinks.json File

Create a file at: `<your_django_project>/static/.well-known/assetlinks.json`

**File content:**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.app.lorryappuser",
    "sha256_cert_fingerprints": [
      "A9:95:FE:5B:EF:81:3E:68:F2:FB:DD:D7:FF:EC:7B:06:64:41:F6:73:A0:D9:CC:1B:58:52:65:6C:F1:CE:62:BA"
    ]
  }
}]
```

### Step 2: Configure Django to Serve Static Files

In your `settings.py`:

```python
import os

# Static files configuration
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

STATICFILES_DIRS = [
    os.path.join(BASE_DIR, 'static'),
]
```

### Step 3: Add URL Pattern for assetlinks.json

In your main `urls.py`:

```python
from django.urls import path, re_path
from django.views.static import serve
from django.conf import settings
import os

urlpatterns = [
    # ... your existing patterns ...
    
    # Serve assetlinks.json for Android App Links
    re_path(
        r'^\.well-known/assetlinks\.json$',
        serve,
        {
            'document_root': os.path.join(settings.BASE_DIR, 'static/.well-known'),
            'path': 'assetlinks.json',
        },
        name='assetlinks'
    ),
]
```

**Alternative approach (using a view):**

Create a view in `views.py`:

```python
from django.http import JsonResponse

def assetlinks(request):
    """Serve Android App Links verification file"""
    data = [{
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
            "namespace": "android_app",
            "package_name": "com.app.lorryappuser",
            "sha256_cert_fingerprints": [
                "A9:95:FE:5B:EF:81:3E:68:F2:FB:DD:D7:FF:EC:7B:06:64:41:F6:73:A0:D9:CC:1B:58:52:65:6C:F1:CE:62:BA"
            ]
        }
    }]
    return JsonResponse(data, safe=False)
```

Then in `urls.py`:

```python
from .views import assetlinks

urlpatterns = [
    # ... your existing patterns ...
    path('.well-known/assetlinks.json', assetlinks, name='assetlinks'),
]
```

---

## Part 2: Handle Share URLs

### Step 4: Create Trip Share View

Create a new view to handle the share URL: `share/trip/<trip_id>`

**Option A: Redirect to App (Recommended)**

```python
from django.shortcuts import redirect, get_object_or_404
from django.http import HttpResponse
from .models import Trip  # Your Trip model

def share_trip(request, trip_id):
    """
    Handle trip share links
    - If opened on mobile with app installed: Opens in app via deep link
    - If opened in browser: Shows a web page with trip details
    """
    
    # Verify trip exists
    trip = get_object_or_404(Trip, id=trip_id)
    
    # Get user agent to detect mobile
    user_agent = request.META.get('HTTP_USER_AGENT', '').lower()
    is_mobile = any(x in user_agent for x in ['android', 'iphone', 'ipad'])
    
    if is_mobile:
        # For mobile devices, return HTML with app deep link
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Open in Lorry App</title>
            <script>
                // Try to open the app
                window.location.href = "lorry://trip/{trip_id}";
                
                // Fallback to Play Store after 2 seconds if app not installed
                setTimeout(function() {{
                    window.location.href = "https://play.google.com/store/apps/details?id=com.app.lorryappuser";
                }}, 2000);
            </script>
        </head>
        <body>
            <div style="text-align: center; padding: 50px; font-family: Arial, sans-serif;">
                <h2>Opening Lorry App...</h2>
                <p>If the app doesn't open, <a href="https://play.google.com/store/apps/details?id=com.app.lorryappuser">download it from Play Store</a></p>
            </div>
        </body>
        </html>
        """
        return HttpResponse(html)
    else:
        # For desktop browsers, show trip details page
        return render(request, 'trip_share.html', {'trip': trip})
```

**Option B: Show Trip Details Web Page**

```python
from django.shortcuts import render, get_object_or_404
from .models import Trip

def share_trip(request, trip_id):
    """Display trip details on web page"""
    trip = get_object_or_404(Trip, id=trip_id)
    
    context = {
        'trip': trip,
        'app_link': f'lorry://trip/{trip_id}',
        'play_store_link': 'https://play.google.com/store/apps/details?id=com.app.lorryappuser',
    }
    
    return render(request, 'trip_share.html', context)
```

### Step 5: Add URL Pattern for Share

In your `urls.py`:

```python
from .views import share_trip

urlpatterns = [
    # ... your existing patterns ...
    
    # Trip sharing URL
    path('share/trip/<uuid:trip_id>/', share_trip, name='share_trip'),
]
```

**Note:** Use `<uuid:trip_id>` if your trip ID is a UUID, or `<str:trip_id>` for string IDs.

### Step 6: Create Trip Share Template (Optional)

Create `templates/trip_share.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trip Details - Lorry App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        h1 {
            color: #111827;
            margin-bottom: 24px;
        }
        .info-row {
            margin-bottom: 16px;
            padding-bottom: 16px;
            border-bottom: 1px solid #eee;
        }
        .label {
            color: #6B7280;
            font-size: 14px;
            margin-bottom: 4px;
        }
        .value {
            color: #111827;
            font-size: 16px;
            font-weight: 500;
        }
        .btn {
            display: inline-block;
            background-color: #111827;
            color: white;
            padding: 12px 24px;
            border-radius: 8px;
            text-decoration: none;
            margin-top: 24px;
            text-align: center;
        }
        .btn:hover {
            background-color: #374151;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>🚛 Trip Details</h1>
        
        <div class="info-row">
            <div class="label">Pickup Location</div>
            <div class="value">{{ trip.pickup_location }}</div>
        </div>
        
        <div class="info-row">
            <div class="label">Drop Location</div>
            <div class="value">{{ trip.drop_location }}</div>
        </div>
        
        <div class="info-row">
            <div class="label">Vehicle Size</div>
            <div class="value">{{ trip.vehicle_size|default:"Not specified" }}</div>
        </div>
        
        <div class="info-row">
            <div class="label">Load Type</div>
            <div class="value">{{ trip.load_type }}</div>
        </div>
        
        <div class="info-row">
            <div class="label">Amount</div>
            <div class="value">₹{{ trip.amount|default:"Not specified" }}</div>
        </div>
        
        <a href="{{ app_link }}" class="btn">Open in Lorry App</a>
        <br>
        <a href="{{ play_store_link }}" class="btn" style="background-color: #10B981;">Download App</a>
    </div>
</body>
</html>
```

---

## Part 3: Testing

### Test 1: Verify assetlinks.json

Open in browser:
```
https://lorry.workwista.com/.well-known/assetlinks.json
```

You should see the JSON content with your package name and SHA-256 fingerprint.

### Test 2: Verify Share URL

Open in browser:
```
https://lorry.workwista.com/share/trip/7233d3da-af84-47a6-b49d-d892da9d67c7
```

You should see either:
- A web page with trip details (if using Option B)
- A redirect page (if using Option A)

### Test 3: Test on Mobile Device

1. Share a trip from the app
2. Click the link on the same or different device
3. The app should open automatically (if installed)
4. If app not installed, should redirect to Play Store

---

## Part 4: Production Deployment

### For Production Server (Nginx/Apache)

If using Nginx, add this to your server block:

```nginx
location /.well-known/assetlinks.json {
    alias /path/to/your/static/.well-known/assetlinks.json;
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
}
```

If using Apache, add to `.htaccess`:

```apache
<Files "assetlinks.json">
    Header set Content-Type "application/json"
    Header set Access-Control-Allow-Origin "*"
</Files>
```

### Collect Static Files

Run this command before deploying:

```bash
python manage.py collectstatic
```

---

## Summary Checklist

- [ ] Create `static/.well-known/assetlinks.json` with correct package name and SHA-256
- [ ] Add URL pattern for `.well-known/assetlinks.json`
- [ ] Create `share_trip` view to handle `share/trip/<trip_id>/`
- [ ] Add URL pattern for `share/trip/<trip_id>/`
- [ ] Create `trip_share.html` template (optional)
- [ ] Test assetlinks.json is accessible
- [ ] Test share URL works in browser
- [ ] Test deep linking on mobile device
- [ ] Deploy to production and run `collectstatic`

---

## Troubleshooting

### Issue: 404 on assetlinks.json
- Check file exists at `static/.well-known/assetlinks.json`
- Verify URL pattern is correct
- Run `python manage.py collectstatic`
- Check Nginx/Apache configuration

### Issue: 404 on share URL
- Verify URL pattern matches: `share/trip/<uuid:trip_id>/`
- Check if trip ID format is correct (UUID vs string)
- Verify view is imported in urls.py

### Issue: App doesn't open on mobile
- Verify assetlinks.json is publicly accessible
- Check SHA-256 fingerprint matches your app's keystore
- Wait 24-48 hours for Google to verify the association
- Test with custom scheme: `lorry://trip/{trip_id}`

---

## Contact

If you need help with implementation, please provide:
1. Your Django version
2. Current URL patterns structure
3. Any error messages you're seeing
