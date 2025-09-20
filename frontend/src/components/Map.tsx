"use client";

import { useEffect, useRef } from 'react';
import * as tt from '@tomtom-international/web-sdk-maps';
import '@tomtom-international/web-sdk-maps/dist/maps.css';
import Papa from 'papaparse';

const apiKey = "pCKjhiDCnrgyjAqbqaeEMeJYmenJGWz6";
const TRAFFIC_INCIDENTS_STYLE = "s0";
const TRAFFIC_FLOW_STYLE = "2/flow_relative-light";

interface SafetyData {
  pincode: string;
  latitude: number;
  longitude: number;
  safety_score: number;
}

interface Tourist {
  id: string;
  name: string;
  location: [number, number];
  lastSeen: string;
}

interface MapProps {
  center?: [number, number];
}

// Initial tourist positions (will be updated with safety data points)
const tourists: Tourist[] = [
  { id: 'tourist-001', name: 'Craig', location: [91.7162, 26.1345], lastSeen: '2 minutes ago' },
  { id: 'tourist-002', name: 'Saish', location: [91.7462, 26.1545], lastSeen: '5 minutes ago' },
  { id: 'tourist-003', name: 'Om', location: [91.7562, 26.1245], lastSeen: '1 minute ago' },
  { id: 'tourist-004', name: 'Palak', location: [91.7262, 26.1645], lastSeen: '3 minutes ago' },
  { id: 'tourist-005', name: 'Gargi', location: [91.7662, 26.1445], lastSeen: '7 minutes ago' },
  { id: 'tourist-006', name: 'Pradyum', location: [91.7362, 26.1145], lastSeen: 'just now' },
];

// Function to update tourist positions with a very small random movement
const updateTouristPositions = (tourists: Tourist[]): Tourist[] => {
  return tourists.map(tourist => ({
    ...tourist,
    location: [
      tourist.location[0] + (Math.random() - 0.5) * 0.0002, // Very small longitude change
      tourist.location[1] + (Math.random() - 0.5) * 0.0002  // Very small latitude change
    ] as [number, number],
    lastSeen: 'just now'
  }));
};

export default function Map({ center = [91.7362, 26.1445] }: MapProps) {
  const mapElement = useRef<HTMLDivElement>(null);
  const map = useRef<tt.Map | null>(null);
  const safetyData = useRef<SafetyData[]>([]);

  const loadSafetyData = async () => {
    const response = await fetch('/pincode_coordinates_with_safety_scores.csv');
    const text = await response.text();

    return new Promise<SafetyData[]>((resolve) => {
      Papa.parse(text, {
        header: true,
        complete: (results) => {
          const data = results.data as SafetyData[];
          resolve(data.map(row => ({
            ...row,
            latitude: parseFloat(row.latitude as unknown as string),
            longitude: parseFloat(row.longitude as unknown as string),
            safety_score: parseFloat(row.safety_score as unknown as string)
          })));
        }
      });
    });
  };

  const getColorFromScore = (score: number, minScore: number, maxScore: number) => {
    const normalizedScore = (score - minScore) / (maxScore - minScore);
    // Brighter color scale from red (unsafe) to green (safe)
    const colors = [
      { threshold: 0, color: '#FF1E1E' },    // Bright red for most dangerous
      { threshold: 0.25, color: '#FF4E11' }, // Bright orange-red
      { threshold: 0.5, color: '#FFA200' },  // Bright orange
      { threshold: 0.75, color: '#FFFF00' }, // Bright yellow
      { threshold: 1, color: '#00FF00' }     // Bright green for safest
    ];

    for (let i = 1; i < colors.length; i++) {
      if (normalizedScore <= colors[i].threshold) {
        return colors[i - 1].color;
      }
    }
    return colors[colors.length - 1].color;
  }; const addHeatmapLayer = (data: SafetyData[]) => {
    if (!map.current) return;

    const maxScore = Math.max(...data.map(d => d.safety_score));
    const minScore = Math.min(...data.map(d => d.safety_score));

    // Add circle layer for precise location visualization
    map.current.addSource('safety-points', {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: data.map(point => ({
          type: 'Feature',
          properties: {
            safety_score: point.safety_score,
            color: getColorFromScore(point.safety_score, minScore, maxScore)
          },
          geometry: {
            type: 'Point',
            coordinates: [point.longitude, point.latitude]
          }
        }))
      }
    });

    // Add circles for precise locations
    map.current.addLayer({
      id: 'safety-points',
      type: 'circle',
      source: 'safety-points',
      paint: {
        'circle-radius': 6, // Slightly smaller circles
        'circle-color': ['get', 'color'],
        'circle-opacity': 0.8,
        'circle-stroke-width': 1.5,
        'circle-stroke-color': '#ffffff'
      }
    });

    // Add heatmap layer
    map.current.addLayer({
      id: 'heatmap',
      type: 'heatmap',
      source: 'safety-points',
      paint: {
        'heatmap-weight': [
          'interpolate',
          ['linear'],
          ['get', 'safety_score'],
          minScore, 1,
          maxScore, 0
        ],
        'heatmap-intensity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          0, 1.5,    // Increased base intensity
          9, 4,      // Increased max intensity
          12, 6      // Even more intense at high zoom
        ],
        'heatmap-color': [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0, 'rgba(255,255,255,0)',
          0.1, 'rgba(255,30,30,0.8)',    // Bright red for highest risk
          0.3, 'rgba(255,78,17,0.85)',   // Bright orange-red
          0.5, 'rgba(255,162,0,0.9)',    // Bright orange
          0.7, 'rgba(255,255,0,0.95)',   // Bright yellow
          1, 'rgba(0,255,0,1)'           // Bright green for safest
        ],
        'heatmap-radius': [
          'interpolate',
          ['linear'],
          ['zoom'],
          0, 4,      // Increased base radius
          9, 25,     // Increased mid-zoom radius
          12, 35,    // Larger radius at high zoom
          15, 50     // Even larger at very high zoom
        ],
        'heatmap-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          7, 0.7,
          12, 0.85,
          15, 0.9
        ]
      }
    });

    // Add click interaction
    map.current.on('click', 'safety-points', (e: tt.MapLayerMouseEvent<'click'>) => {
      const feature = e.features?.[0];
      if (!feature || feature.geometry.type !== 'Point') return; // type guard

      const point = feature.geometry as GeoJSON.Point;
      const coordinates = new tt.LngLat(point.coordinates[0], point.coordinates[1]);
      const safetyScore = feature.properties?.safety_score;
      if (!safetyScore) return;

      const popupContent = `
    <div class="p-2">
      <h3 class="font-bold mb-1">Safety Information</h3>
      <p>Safety Score: ${Number(safetyScore).toFixed(2)}</p>
      <p>Risk Level: ${Number(safetyScore) < 0.3
          ? 'High'
          : Number(safetyScore) < 0.7
            ? 'Medium'
            : 'Low'
        }</p>
    </div>
  `;

      new tt.Popup().setLngLat(coordinates).setHTML(popupContent).addTo(map.current!);
    });

    // Change cursor on hover
    map.current.on('mouseenter', 'safety-points', () => {
      if (map.current) map.current.getCanvas().style.cursor = 'pointer';
    });

    map.current.on('mouseleave', 'safety-points', () => {
      if (map.current) map.current.getCanvas().style.cursor = '';
    });
  };

  useEffect(() => {
    if (!mapElement.current) return;

    map.current = tt.map({
      key: apiKey,
      container: mapElement.current,
      center: center,
      zoom: 11, // Zoomed out a bit to show more context
      style: `https://api.tomtom.com/style/1/style/22.2.1-*?map=2/basic_street-light&traffic_incidents=incidents_${TRAFFIC_INCIDENTS_STYLE}&poi=2/poi_light&traffic_flow=${TRAFFIC_FLOW_STYLE}`,
      stylesVisibility: {
        trafficIncidents: true,
        trafficFlow: true,
      },
    });

    const addTouristMarkers = (safetyData: SafetyData[]) => {
      if (!map.current) return;

      // Filter safety data points specifically for Guwahati region
      const guwahatiPoints = safetyData.filter(point => {
        // More precise Guwahati boundaries based on heatmap data
        return point.longitude >= 91.71 && point.longitude <= 91.78 &&
          point.latitude >= 26.11 && point.latitude <= 26.18;
      });

      // Group points by risk level
      const riskLevels = guwahatiPoints.reduce((acc, point) => {
        if (point.safety_score <= 0.3) acc.high.push(point);
        else if (point.safety_score <= 0.7) acc.medium.push(point);
        else acc.low.push(point);
        return acc;
      }, { high: [], medium: [], low: [] } as { high: SafetyData[], medium: SafetyData[], low: SafetyData[] });

      // Select diverse points for tourists
      const selectedPoints = [
        riskLevels.high[Math.floor(Math.random() * riskLevels.high.length)], // Craig in high risk
        riskLevels.high[Math.floor(Math.random() * riskLevels.high.length)], // Saish in high risk
        riskLevels.medium[Math.floor(Math.random() * riskLevels.medium.length)], // Om in medium risk
        riskLevels.medium[Math.floor(Math.random() * riskLevels.medium.length)], // Palak in medium risk
        riskLevels.low[Math.floor(Math.random() * riskLevels.low.length)], // Gargi in low risk
        riskLevels.low[Math.floor(Math.random() * riskLevels.low.length)], // Pradyum in low risk
      ].map(point => point || guwahatiPoints[0]); // Fallback to first point if any category is empty

      const updatedTourists = tourists.map((tourist, index) => ({
        ...tourist,
        location: [
          selectedPoints[index].longitude,
          selectedPoints[index].latitude
        ] as [number, number]
      }));

      // Add tourist markers source
      map.current.addSource('tourists', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: updatedTourists.map(tourist => ({
            type: 'Feature',
            properties: {
              id: tourist.id,
              name: tourist.name,
              lastSeen: tourist.lastSeen
            },
            geometry: {
              type: 'Point',
              coordinates: tourist.location
            }
          }))
        }
      });

      // Add pulse effect layer
      map.current.addLayer({
        id: 'tourists-pulse',
        type: 'circle',
        source: 'tourists',
        paint: {
          'circle-radius': [
            'interpolate',
            ['linear'],
            ['get', 'pulse'],
            0, 15,
            1, 25
          ],
          'circle-color': '#1E90FF',
          'circle-opacity': [
            'interpolate',
            ['linear'],
            ['get', 'pulse'],
            0, 0.4,
            1, 0
          ]
        }
      });

      // Add tourist markers layer
      map.current.addLayer({
        id: 'tourists-layer',
        type: 'circle',
        source: 'tourists',
        paint: {
          'circle-radius': 8,
          'circle-color': '#1E90FF',
          'circle-stroke-width': 2,
          'circle-stroke-color': '#ffffff'
        }
      });

      // Add tourist labels
      map.current.addLayer({
        id: 'tourist-labels',
        type: 'symbol',
        source: 'tourists',
        layout: {
          'text-field': ['get', 'name'],
          'text-anchor': 'top',
          'text-offset': [0, 1.5],
          'text-size': 12,
          'text-allow-overlap': true,
          'text-ignore-placement': true
        },
        paint: {
          'text-color': '#1E90FF',
          'text-halo-color': '#ffffff',
          'text-halo-width': 2
        }
      });

      // Animate tourists with slow movement
      let frame = 0;
      let lastMoveTime = Date.now();
      let currentTourists = [...updatedTourists];

      const animate = () => {
        const currentTime = Date.now();
        frame = (frame + 1) % 120; // Slower pulse cycle

        // Update positions every 5-10 seconds (random interval)
        if (currentTime - lastMoveTime > (5000 + Math.random() * 5000)) {
          currentTourists = updateTouristPositions(currentTourists);
          lastMoveTime = currentTime;
        }

        const features = currentTourists.map(tourist => ({
          type: 'Feature',
          properties: {
            id: tourist.id,
            name: tourist.name,
            lastSeen: tourist.lastSeen,
            pulse: (Math.sin(frame / 60 * Math.PI) + 1) / 2 // Slower pulse effect
          },
          geometry: {
            type: 'Point',
            coordinates: tourist.location
          }
        }));

        if (map.current?.getSource('tourists')) {
          const source = map.current.getSource('tourists') as tt.GeoJSONSource;
          // source.setData();
        }

        requestAnimationFrame(animate);
      };

      animate();

      // Add click handler for tourist markers
      map.current.on('click', 'tourists-layer', (e: tt.MapLayerMouseEvent<'click'>) => {
        const feature = e.features?.[0];
        if (!feature || !feature.properties) return;
        if (feature.geometry.type !== 'Point') return; // ensure coordinates exist

        const { id, name, lastSeen } = feature.properties;
        const point = feature.geometry as GeoJSON.Point;
const coordinates = new tt.LngLat(point.coordinates[0], point.coordinates[1]);


        const popupContent = `
    <div class="p-4 min-w-[250px] bg-white/95 backdrop-blur-sm">
      <div class="flex items-center gap-3 mb-3">
        <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-bold text-lg">
          ${name.charAt(0)}
        </div>
        <div>
          <h3 class="font-bold text-lg text-gray-900">${name}</h3>
          <p class="text-sm text-gray-500">Tourist ID: ${id}</p>
        </div>
      </div>
      <div class="space-y-2 mb-4">
        <div class="flex items-center gap-2">
          <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></div>
          <p class="text-sm text-gray-600">Last seen: ${lastSeen}</p>
        </div>
        <div class="text-sm text-gray-500">Current Location: Active Zone</div>
      </div>
      <a href="/police/tourist-details/${id}" 
         class="block w-full text-center bg-blue-500 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-600 transition-colors shadow-sm">
        View Tourist Details
      </a>
    </div>
  `;

        new tt.Popup().setLngLat(coordinates).setHTML(popupContent).addTo(map.current!);
      });

      // Change cursor on hover for tourist markers
      map.current.on('mouseenter', 'tourists-layer', () => {
        if (map.current) map.current.getCanvas().style.cursor = 'pointer';
      });

      map.current.on('mouseleave', 'tourists-layer', () => {
        if (map.current) map.current.getCanvas().style.cursor = '';
      });
    };

    map.current.on('load', async function () {
      const data = await loadSafetyData();
      safetyData.current = data;
      addHeatmapLayer(data);
      addTouristMarkers(data);
    });

    return () => {
      map.current?.remove();
    };
  }, []);

  useEffect(() => {
    if (!map.current) return;
    map.current.setCenter(center);
  }, [center]);

  return (
    <div className="relative w-full h-full rounded-lg overflow-hidden">
      <div ref={mapElement} className="w-full h-full" />
      <div className="absolute bottom-4 right-4 bg-white/90 backdrop-blur-sm p-4 rounded-lg shadow-lg border border-gray-200">
        <h3 className="text-sm font-semibold mb-2">Safety Score Legend</h3>
        <div className="space-y-2">
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 rounded-full shadow-inner" style={{ backgroundColor: '#FF1E1E' }}></div>
            <span className="text-xs">Very High Risk (0.0-0.25)</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 rounded-full shadow-inner" style={{ backgroundColor: '#FF4E11' }}></div>
            <span className="text-xs">High Risk (0.25-0.5)</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 rounded-full shadow-inner" style={{ backgroundColor: '#FFA200' }}></div>
            <span className="text-xs">Moderate Risk (0.5-0.75)</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 rounded-full shadow-inner" style={{ backgroundColor: '#FFFF00' }}></div>
            <span className="text-xs">Low Risk (0.75-0.9)</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 rounded-full shadow-inner" style={{ backgroundColor: '#00FF00' }}></div>
            <span className="text-xs">Very Low Risk (0.9-1.0)</span>
          </div>
        </div>
      </div>
    </div>
  );
}
