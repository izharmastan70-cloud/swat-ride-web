/**
 * SWAT Ride Map - Leaflet.js Map Control
 * 
 * Handles OpenStreetMap display, marker placement, and user interaction.
 * Uses Leaflet.js for rendering and OSM tiles for base map.
 */

class SwatRideMap {
    constructor() {
        // Map instance
        this.map = null;
        
        // Selected location
        this.selectedLocation = null;
        this.selectedLocationName = 'Custom Location';
        
        // Marker
        this.mainMarker = null;
        this.userMarker = null;
        
        // Marker cluster group
        this.markerCluster = null;
        
        // Drawing mode
        this.isDrawingMode = false;
        
        // Swat region center
        this.SWAT_CENTER = { lat: 34.7682, lng: 72.3345 };
        this.SWAT_BOUNDS = [
            [34.0, 72.0],   // Southwest
            [36.0, 74.0]    // Northeast
        ];
        
        // Default zoom level
        this.DEFAULT_ZOOM = 15;
    }
    
    /**
     * Initialize the map
     */
    init() {
        // Create map
        this.map = L.map('map').setView(
            [this.SWAT_CENTER.lat, this.SWAT_CENTER.lng],
            this.DEFAULT_ZOOM
        );
        
        // Set max bounds to Swat region
        this.map.setMaxBounds(this.SWAT_BOUNDS);
        
        // Add OSM tile layer
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19,
            minZoom: 5,
            crossOrigin: true
        }).addTo(this.map);
        
        // Initialize marker cluster group
        this.markerCluster = L.markerClusterGroup();
        this.map.addLayer(this.markerCluster);
        
        // Add initial marker at center
        this.setLocation(this.SWAT_CENTER.lat, this.SWAT_CENTER.lng, 'Swat Region');
        
        // Add map event listeners
        this._setupEventListeners();
        
        // Setup UI controls
        this._setupControls();
        
        // Set initial location info
        this._updateLocationInfo(this.SWAT_CENTER.lat, this.SWAT_CENTER.lng);
    }
    
    /**
     * Set location and place marker
     */
    setLocation(lat, lng, name = 'Selected Location') {
        this.selectedLocation = { lat, lng };
        this.selectedLocationName = name;
        
        // Remove existing marker
        if (this.mainMarker) {
            this.map.removeLayer(this.mainMarker);
        }
        
        // Add new marker
        this.mainMarker = L.marker([lat, lng], {
            draggable: true,
            icon: this._getMarkerIcon('selected')
        }).addTo(this.map);
        
        // Add drag event listener
        this.mainMarker.on('drag', (e) => {
            const newLat = e.target.getLatLng().lat;
            const newLng = e.target.getLatLng().lng;
            this._updateLocationInfo(newLat, newLng);
        });
        
        // Update info panel
        this._updateLocationInfo(lat, lng);
        
        // Center map on marker
        this.map.setView([lat, lng], this.DEFAULT_ZOOM);
    }
    
    /**
     * Get current device location using Geolocation API
     */
    getCurrentLocation(callback) {
        if (!navigator.geolocation) {
            console.error('Geolocation not supported');
            if (callback) callback(null);
            return;
        }
        
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const lat = position.coords.latitude;
                const lng = position.coords.longitude;
                
                // Place user location marker
                if (this.userMarker) {
                    this.map.removeLayer(this.userMarker);
                }
                
                this.userMarker = L.marker([lat, lng], {
                    icon: this._getMarkerIcon('current'),
                    title: 'Your Location'
                }).addTo(this.map);
                
                // Set as selected location
                this.setLocation(lat, lng, 'Current Location');
                
                // Callback
                if (callback) {
                    callback({
                        latitude: lat,
                        longitude: lng,
                        accuracy: position.coords.accuracy
                    });
                }
            },
            (error) => {
                console.error('Geolocation error:', error.message);
                alert('Unable to get your location. Please enable GPS and try again.');
                if (callback) callback(null);
            },
            {
                timeout: 10000,
                enableHighAccuracy: true,
                maximumAge: 0
            }
        );
    }
    
    /**
     * Enable/disable drawing mode for manual pin placement
     */
    setDrawingMode(enabled) {
        this.isDrawingMode = enabled;
        
        if (enabled) {
            this.map.dragging.disable();
            this.map.scrollWheelZoom.disable();
            this.map.style.cursor = 'crosshair';
            document.body.style.cursor = 'crosshair';
        } else {
            this.map.dragging.enable();
            this.map.scrollWheelZoom.enable();
            this.map.style.cursor = 'grab';
            document.body.style.cursor = 'default';
        }
    }
    
    /**
     * Clear all markers
     */
    clearMarkers() {
        this.markerCluster.clearLayers();
        if (this.mainMarker) {
            this.map.removeLayer(this.mainMarker);
            this.mainMarker = null;
        }
        if (this.userMarker) {
            this.map.removeLayer(this.userMarker);
            this.userMarker = null;
        }
        this.selectedLocation = null;
    }
    
    /**
     * Add custom pin to map
     */
    addPin(lat, lng, label = '', color = '#FF0000') {
        const marker = L.marker([lat, lng], {
            icon: this._getCustomIcon(label, color)
        }).bindPopup(label).addTo(this.markerCluster);
        
        return marker;
    }
    
    /**
     * Setup event listeners
     */
    _setupEventListeners() {
        // Map click event
        this.map.on('click', (e) => {
            if (this.isDrawingMode) {
                this.setLocation(e.latlng.lat, e.latlng.lng, 'Custom Location');
            }
        });
        
        // Zoom event
        this.map.on('zoomend', () => {
            console.log('Zoom level:', this.map.getZoom());
        });
    }
    
    /**
     * Setup UI controls
     */
    _setupControls() {
        // Current location button
        const currentLocationBtn = document.getElementById('current-location-btn');
        if (currentLocationBtn) {
            currentLocationBtn.addEventListener('click', () => {
                currentLocationBtn.disabled = true;
                currentLocationBtn.textContent = '⏳ Getting location...';
                
                this.getCurrentLocation(() => {
                    currentLocationBtn.disabled = false;
                    currentLocationBtn.innerHTML = '<span class="icon">📍</span><span class="text">My Location</span>';
                });
            });
        }
        
        // Clear pins button
        const clearPinsBtn = document.getElementById('clear-pins-btn');
        if (clearPinsBtn) {
            clearPinsBtn.addEventListener('click', () => {
                this.clearMarkers();
            });
        }
        
        // Confirm location button
        const confirmBtn = document.getElementById('confirm-location-btn');
        if (confirmBtn) {
            confirmBtn.addEventListener('click', () => {
                if (this.selectedLocation) {
                    // Dispatch custom event that Flutter can listen to
                    const event = new CustomEvent('locationSelected', {
                        detail: {
                            latitude: this.selectedLocation.lat,
                            longitude: this.selectedLocation.lng,
                            addressName: this.selectedLocationName,
                            timestamp: new Date().toISOString()
                        }
                    });
                    document.dispatchEvent(event);
                    
                    console.log('Location confirmed:', this.selectedLocation);
                }
            });
        }
    }
    
    /**
     * Update location info panel
     */
    _updateLocationInfo(lat, lng) {
        this.selectedLocation = { lat, lng };
        
        const titleEl = document.getElementById('location-title');
        const coordsEl = document.getElementById('location-coords');
        
        if (titleEl) {
            titleEl.textContent = this.selectedLocationName;
        }
        
        if (coordsEl) {
            coordsEl.textContent = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
        }
    }
    
    /**
     * Get marker icon
     */
    _getMarkerIcon(type = 'selected') {
        if (type === 'current') {
            return L.icon({
                iconUrl: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48Y2lyY2xlIGN4PSIxNiIgY3k9IjE2IiByPSI5IiBmaWxsPSIjMDA0Q0ZGIiBzdHJva2U9IndoaXRlIiBzdHJva2Utd2lkdGg9IjIiLz48Y2lyY2xlIGN4PSIxNiIgY3k9IjE2IiByPSI0IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPg==',
                iconSize: [32, 32],
                iconAnchor: [16, 16],
                popupAnchor: [0, -16]
            });
        }
        
        // Default selected marker
        return L.icon({
            iconUrl: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDQiIGhlaWdodD0iNTYiIHZpZXdCb3g9IjAgMCA0NCA1NiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjIgMEM5Ljg1IDE1LjMwNjUgMiAyNC4yNzMgMiAzMi41QzIgNDYuNDMyIDEwLjE1IDU0IDIyIDU0QzMzLjg1IDU0IDQyIDQ2LjQzMiA0MiAzMi41QzQyIDI0LjI3MyAzNC4xNSAxNS4zMDY1IDIyIDBaMjIgNDNDMTUuMzczIDQzIDEwIDM3LjYyNyAxMCAzMUMxMCAyNC4zNzMgMTUuMzczIDE5IDIyIDE5QzI4LjYyNyAxOSAzNCAyNC4zNzMgMzQgMzFDMzQgMzcuNjI3IDI4LjYyNyA0MyAyMiA0M1oiIGZpbGw9IiNGRjAwMDAiLz48L3N2Zz4=',
            iconSize: [44, 56],
            iconAnchor: [22, 56],
            popupAnchor: [0, -56]
        });
    }
    
    /**
     * Get custom icon for pins
     */
    _getCustomIcon(label, color) {
        return L.icon({
            iconUrl: `data:image/svg+xml;base64,${this._encodeIcon(label, color)}`,
            iconSize: [32, 32],
            iconAnchor: [16, 16],
            popupAnchor: [0, -16]
        });
    }
    
    /**
     * Encode SVG icon as base64
     */
    _encodeIcon(label, color) {
        const svg = `<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="16" cy="16" r="14" fill="${color}" stroke="white" stroke-width="2"/>
            <text x="16" y="22" font-size="12" font-weight="bold" fill="white" text-anchor="middle">${label.charAt(0).toUpperCase()}</text>
        </svg>`;
        
        return btoa(svg);
    }
    
    /**
     * Export location as JSON
     */
    exportLocation() {
        if (!this.selectedLocation) return null;
        
        return {
            latitude: this.selectedLocation.lat,
            longitude: this.selectedLocation.lng,
            addressName: this.selectedLocationName,
            timestamp: new Date().toISOString(),
            selectionMethod: 'mapPin'
        };
    }
}

// Create global instance
window.swatRideMap = new SwatRideMap();
