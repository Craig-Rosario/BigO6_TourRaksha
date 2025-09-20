"use client";

import { useEffect, useRef, useState, useCallback } from 'react';
import * as tt from '@tomtom-international/web-sdk-maps';
import '@tomtom-international/web-sdk-maps/dist/maps.css';
import Papa from 'papaparse';
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { 
  Play, 
  Pause, 
  RotateCcw, 
  Layers, 
  Shield
} from "lucide-react";

const apiKey = "pCKjhiDCnrgyjAqbqaeEMeJYmenJGWz6";

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
  status: 'safe' | 'warning' | 'danger';
  safetyScore: number;
}

interface Alert {
  id: string;
  touristId: string;
  touristName: string;
  type: string;
  message: string;
  location: [number, number];
  timestamp: string;
}

interface OptimizedMapProps {
  center?: [number, number];
  onTouristSelect?: (tourist: Tourist) => void;
  onAlertGenerated?: (alert: Alert) => void;
}

// Enhanced tourist data with safety statuses
const initialTourists: Tourist[] = [
  { id: 'TRK001', name: 'Craig Wilson', location: [72.8677, 19.0760], lastSeen: '2 min ago', status: 'safe', safetyScore: 85 },
  { id: 'TRK002', name: 'Saish Kumar', location: [72.8877, 19.0860], lastSeen: '5 min ago', status: 'warning', safetyScore: 65 },
  { id: 'TRK003', name: 'Om Patel', location: [72.8977, 19.0660], lastSeen: '1 min ago', status: 'safe', safetyScore: 92 },
  { id: 'TRK004', name: 'Palak Singh', location: [72.8577, 19.0960], lastSeen: '15 min ago', status: 'danger', safetyScore: 35 },
  { id: 'TRK005', name: 'Gargi Shah', location: [72.8777, 19.0560], lastSeen: '3 min ago', status: 'safe', safetyScore: 78 },
  { id: 'TRK006', name: 'Pradyum Roy', location: [72.8477, 19.0860], lastSeen: 'just now', status: 'safe', safetyScore: 88 },
];

export default function OptimizedMap({ 
  center = [72.8777, 19.0760], 
  onTouristSelect,
  onAlertGenerated 
}: OptimizedMapProps) {
  const mapElement = useRef<HTMLDivElement>(null);
  const map = useRef<tt.Map | null>(null);
  const safetyData = useRef<SafetyData[]>([]);
  const [tourists, setTourists] = useState<Tourist[]>(initialTourists);
  const [isAnimating, setIsAnimating] = useState(true);
  const [currentLayer, setCurrentLayer] = useState<'heatmap' | 'points' | 'both'>('both');
  const [stats, setStats] = useState({
    totalTourists: 0,
    safeTourists: 0,
    warningTourists: 0,
    dangerTourists: 0,
    avgSafetyScore: 0
  });
  const animationRef = useRef<NodeJS.Timeout | null>(null);

  // Optimized color generation with better contrast
  const getColorFromScore = useCallback((score: number, alpha: number = 1) => {
    if (score >= 80) return `rgba(16, 185, 129, ${alpha})`; // Green - Safe
    if (score >= 60) return `rgba(245, 158, 11, ${alpha})`; // Amber - Warning  
    if (score >= 40) return `rgba(249, 115, 22, ${alpha})`; // Orange - Caution
    return `rgba(239, 68, 68, ${alpha})`; // Red - Danger
  }, []);

  // Enhanced tourist status colors
  const getStatusColor = useCallback((status: string) => {
    switch (status) {
      case 'safe': return '#10B981';
      case 'warning': return '#F59E0B'; 
      case 'danger': return '#EF4444';
      default: return '#6B7280';
    }
  }, []);

  // Load safety data with caching
  const loadSafetyData = useCallback(async () => {
    try {
      const response = await fetch('/pincode_coordinates_with_safety_scores.csv');
      const text = await response.text();
      
      return new Promise<SafetyData[]>((resolve) => {
        Papa.parse(text, {
          header: true,
          skipEmptyLines: true,
          complete: (results) => {
            const data = results.data as SafetyData[];
            const processedData = data
              .map(row => ({
                ...row,
                latitude: parseFloat(row.latitude as unknown as string),
                longitude: parseFloat(row.longitude as unknown as string),
                safety_score: parseFloat(row.safety_score as unknown as string)
              }))
              .filter(row => !isNaN(row.latitude) && !isNaN(row.longitude) && !isNaN(row.safety_score));
            
            resolve(processedData);
          }
        });
      });
    } catch (error) {
      console.error('Error loading safety data:', error);
      return [];
    }
  }, []);

  // Optimized heatmap layer with clustering
  const addOptimizedHeatmapLayer = useCallback((data: SafetyData[]) => {
    if (!map.current || data.length === 0) return;

    if (map.current.getSource('safety-data')) {
    if (map.current.getLayer('safety-heatmap')) map.current.removeLayer('safety-heatmap');
    if (map.current.getLayer('safety-points')) map.current.removeLayer('safety-points');
    map.current.removeSource('safety-data');
  }

    const maxScore = Math.max(...data.map(d => d.safety_score));
    const minScore = Math.min(...data.map(d => d.safety_score));

    // Create clustered data for better performance
    interface ClusteredPoint extends SafetyData {
      count: number;
    }
    
    const clusteredData = data.reduce((acc: ClusteredPoint[], point) => {
      const existing = acc.find(p => 
        Math.abs(p.latitude - point.latitude) < 0.001 && 
        Math.abs(p.longitude - point.longitude) < 0.001
      );
      
      if (existing) {
        existing.safety_score = (existing.safety_score + point.safety_score) / 2;
        existing.count += 1;
      } else {
        acc.push({ ...point, count: 1 });
      }
      return acc;
    }, []);

    // Add safety data source
    map.current.addSource('safety-data', {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: clusteredData.map(point => ({
          type: 'Feature',
          properties: {
            safety_score: point.safety_score,
            pincode: point.pincode,
            count: point.count,
            color: getColorFromScore(point.safety_score),
            risk_level: point.safety_score >= 80 ? 'Low' : 
                       point.safety_score >= 60 ? 'Medium' : 
                       point.safety_score >= 40 ? 'High' : 'Critical'
          },
          geometry: {
            type: 'Point',
            coordinates: [point.longitude, point.latitude]
          }
        }))
      }
    });

    // Enhanced heatmap layer
    map.current.addLayer({
      id: 'safety-heatmap',
      type: 'heatmap',
      source: 'safety-data',
      layout: {
        visibility: currentLayer === 'points' ? 'none' : 'visible'
      },
      paint: {
        'heatmap-weight': [
          'interpolate',
          ['linear'],
          ['get', 'safety_score'],
          minScore, 1,
          maxScore, 0.3
        ],
        'heatmap-intensity': [
          'interpolate',
          ['exponential', 2],
          ['zoom'],
          0, 0.8,
          9, 2.5,
          12, 4,
          15, 6
        ],
        'heatmap-color': [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0, 'rgba(0,0,0,0)',
          0.1, 'rgba(239,68,68,0.7)',    // Red - High risk
          0.3, 'rgba(249,115,22,0.8)',   // Orange - Medium risk
          0.5, 'rgba(245,158,11,0.9)',   // Amber - Low-medium risk
          0.7, 'rgba(34,197,94,0.95)',   // Green - Low risk
          1, 'rgba(16,185,129,1)'        // Emerald - Very safe
        ],
        'heatmap-radius': [
          'interpolate',
          ['exponential', 2],
          ['zoom'],
          0, 8,
          9, 20,
          12, 30,
          15, 45
        ],
        'heatmap-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          7, 0.8,
          12, 0.9,
          15, 0.95
        ]
      }
    });

    // Enhanced point layer with size based on risk
    map.current.addLayer({
      id: 'safety-points',
      type: 'circle',
      source: 'safety-data',
      layout: {
        visibility: currentLayer === 'heatmap' ? 'none' : 'visible'
      },
      paint: {
        'circle-radius': [
          'interpolate',
          ['linear'],
          ['get', 'safety_score'],
          0, 8,
          50, 6,
          80, 4,
          100, 3
        ],
        'circle-color': ['get', 'color'],
        'circle-opacity': 0.85,
        'circle-stroke-width': [
          'case',
          ['<', ['get', 'safety_score'], 40], 3, // High risk - thicker border
          ['<', ['get', 'safety_score'], 60], 2, // Medium risk
          1 // Low risk
        ],
        'circle-stroke-color': '#ffffff',
        'circle-stroke-opacity': 0.9
      }
    });

    // Add interactive popups
    const popup = new tt.Popup({
      closeButton: false,
      closeOnClick: false
    });

    map.current.on('mouseenter', 'safety-points', (e: any) => {
      map.current!.getCanvas().style.cursor = 'pointer';
      
      const coordinates = e.features[0].geometry.coordinates.slice();
      const { safety_score, pincode, risk_level, count } = e.features[0].properties;
      
      popup.setLngLat(coordinates)
        .setHTML(`
          <div class="p-3 min-w-[200px] bg-white rounded-lg shadow-lg">
            <div class="flex items-center justify-between mb-2">
              <h3 class="font-semibold text-gray-900">Area: ${pincode}</h3>
              <Badge class="text-xs px-2 py-1" style="background-color: ${getColorFromScore(safety_score, 0.2)}; color: ${getColorFromScore(safety_score)}">
                ${risk_level}
              </Badge>
            </div>
            <div class="space-y-1 text-sm text-gray-600">
              <p>Safety Score: <span class="font-medium">${Number(safety_score).toFixed(1)}</span></p>
              <p>Data Points: <span class="font-medium">${count}</span></p>
              <p class="text-xs text-gray-500 mt-2">Click for detailed analysis</p>
            </div>
          </div>
        `)
        .addTo(map.current!);
    });

    map.current.on('mouseleave', 'safety-points', () => {
      map.current!.getCanvas().style.cursor = '';
      popup.remove();
    });

  }, [currentLayer, getColorFromScore]);

  // Enhanced tourist markers with real-time updates
  const addTouristMarkers = useCallback((touristData: Tourist[]) => {
    if (!map.current) return;

    if (map.current.getSource('tourists')) {
    if (map.current.getLayer('tourists-pulse')) map.current.removeLayer('tourists-pulse');
    if (map.current.getLayer('tourists-layer')) map.current.removeLayer('tourists-layer');
    if (map.current.getLayer('tourist-labels')) map.current.removeLayer('tourist-labels');
    map.current.removeSource('tourists');
  }

    // Add tourist source
    map.current.addSource('tourists', {
      type: 'geojson',
      data: {
        type: 'FeatureCollection',
        features: touristData.map(tourist => ({
          type: 'Feature',
          properties: {
            ...tourist,
            statusColor: getStatusColor(tourist.status)
          },
          geometry: {
            type: 'Point',
            coordinates: tourist.location
          }
        }))
      }
    });

    // Pulse effect for alerts
    map.current.addLayer({
      id: 'tourists-pulse',
      type: 'circle',
      source: 'tourists',
      filter: ['==', ['get', 'status'], 'danger'],
      paint: {
        'circle-radius': [
          'interpolate',
          ['linear'],
          ['get', 'pulse'],
          0, 15,
          1, 35
        ],
        'circle-color': '#EF4444',
        'circle-opacity': [
          'interpolate',
          ['linear'],
          ['get', 'pulse'], 
          0, 0.6,
          1, 0
        ]
      }
    });

    // Main tourist markers
    map.current.addLayer({
      id: 'tourists-layer',
      type: 'circle',
      source: 'tourists',
      paint: {
        'circle-radius': [
          'case',
          ['==', ['get', 'status'], 'danger'], 12,
          ['==', ['get', 'status'], 'warning'], 10,
          8
        ],
        'circle-color': ['get', 'statusColor'],
        'circle-stroke-width': 2,
        'circle-stroke-color': '#ffffff',
        'circle-opacity': 0.9
      }
    });

    // Tourist labels
    map.current.addLayer({
      id: 'tourist-labels',
      type: 'symbol',
      source: 'tourists',
      layout: {
        'text-field': ['get', 'name'],
        'text-anchor': 'top',
        'text-offset': [0, 2],
        'text-size': 11,
        'text-allow-overlap': false,
        'symbol-avoid-edges': true
      },
      paint: {
        'text-color': '#1f2937',
        'text-halo-color': '#ffffff',
        'text-halo-width': 2,
        'text-halo-blur': 1
      }
    });

    // Tourist click handler
    map.current.on('click', 'tourists-layer', (e: any) => {
      const tourist = e.features[0].properties as Tourist;
      const coordinates = e.features[0].geometry.coordinates.slice();
      
      if (onTouristSelect) {
        onTouristSelect(tourist);
      }

      const popupContent = `
        <div class="p-4 min-w-[280px] bg-white rounded-lg shadow-xl">
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg shadow-md" 
                   style="background-color: ${getStatusColor(tourist.status)}">
                ${tourist.name.charAt(0)}
              </div>
              <div>
                <h3 class="font-bold text-lg text-gray-900">${tourist.name}</h3>
                <p class="text-sm text-gray-500">ID: ${tourist.id}</p>
              </div>
            </div>
            <Badge class="text-xs px-2 py-1 rounded-full" style="background-color: ${getStatusColor(tourist.status)}20; color: ${getStatusColor(tourist.status)}">
              ${tourist.status.toUpperCase()}
            </Badge>
          </div>
          
          <div class="space-y-3 mb-4">
            <div class="flex items-center gap-2">
              <Activity className="w-4 h-4 text-gray-500" />
              <span class="text-sm text-gray-600">Safety Score: <strong>${tourist.safetyScore}</strong></span>
            </div>
            <div class="flex items-center gap-2">
              <MapPin className="w-4 h-4 text-gray-500" />
              <span class="text-sm text-gray-600">Last seen: ${tourist.lastSeen}</span>
            </div>
            ${tourist.status === 'danger' ? `
              <div class="flex items-center gap-2 p-2 bg-red-50 rounded-lg">
                <AlertTriangle className="w-4 h-4 text-red-500" />
                <span class="text-sm text-red-700 font-medium">Requires immediate attention!</span>
              </div>
            ` : ''}
          </div>
          
          <div class="grid grid-cols-2 gap-2">
            <button class="px-3 py-2 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors">
              View Profile
            </button>
            <button class="px-3 py-2 text-xs font-medium text-gray-600 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
              Send Message
            </button>
          </div>
        </div>
      `;
      
      new tt.Popup()
        .setLngLat(coordinates)
        .setHTML(popupContent)
        .addTo(map.current!);
    });

  }, [getStatusColor, onTouristSelect]);

  // Animation controller
  const animateTourists = useCallback(() => {
    if (!isAnimating || !map.current) return;

    setTourists(prevTourists => {
      const updatedTourists = prevTourists.map(tourist => {
        // Slight random movement
        const newLocation: [number, number] = [
          tourist.location[0] + (Math.random() - 0.5) * 0.0001,
          tourist.location[1] + (Math.random() - 0.5) * 0.0001
        ];

        // Update safety score based on location (simulate)
        const newSafetyScore = Math.max(20, Math.min(100, 
          tourist.safetyScore + (Math.random() - 0.5) * 5
        ));

        // Update status based on safety score
        let newStatus: 'safe' | 'warning' | 'danger' = 'safe';
        if (newSafetyScore < 40) newStatus = 'danger';
        else if (newSafetyScore < 70) newStatus = 'warning';

        return {
          ...tourist,
          location: newLocation,
          safetyScore: Math.round(newSafetyScore),
          status: newStatus,
          lastSeen: Math.random() > 0.9 ? 'just now' : tourist.lastSeen
        };
      });

      // Update map source if it exists
      if (map.current?.getSource('tourists')) {
        const source = map.current.getSource('tourists') as any;
        source.setData({
          type: 'FeatureCollection',
          features: updatedTourists.map(tourist => ({
            type: 'Feature',
            properties: {
              ...tourist,
              statusColor: getStatusColor(tourist.status),
              pulse: Math.sin(Date.now() / 1000) * 0.5 + 0.5
            },
            geometry: {
              type: 'Point',
              coordinates: tourist.location
            }
          }))
        });
      }

      return updatedTourists;
    });

    animationRef.current = setTimeout(animateTourists, 3000); // Update every 3 seconds
  }, [isAnimating, getStatusColor]);

  // Update statistics
  useEffect(() => {
    const safeTourists = tourists.filter(t => t.status === 'safe').length;
    const warningTourists = tourists.filter(t => t.status === 'warning').length;
    const dangerTourists = tourists.filter(t => t.status === 'danger').length;
    const avgSafetyScore = Math.round(
      tourists.reduce((sum, t) => sum + t.safetyScore, 0) / tourists.length
    );

    setStats({
      totalTourists: tourists.length,
      safeTourists,
      warningTourists,
      dangerTourists,
      avgSafetyScore
    });

    // Generate alerts for danger status
    tourists.forEach(tourist => {
      if (tourist.status === 'danger' && onAlertGenerated) {
        onAlertGenerated({
          id: `alert-${tourist.id}-${Date.now()}`,
          touristId: tourist.id,
          touristName: tourist.name,
          type: 'safety_alert',
          message: `Tourist ${tourist.name} is in a high-risk area (Score: ${tourist.safetyScore})`,
          location: tourist.location,
          timestamp: new Date().toISOString()
        });
      }
    });
  }, [tourists, onAlertGenerated]);

  // Initialize map
  useEffect(() => {
    if (!mapElement.current) return;

    map.current = tt.map({
      key: apiKey,
      container: mapElement.current,
      center: center,
      zoom: 12,
      style: 'https://api.tomtom.com/style/1/style/22.2.1-*?map=2/basic_street-light&poi=2/poi_light',
    });

    map.current.on('load', async () => {
      const data = await loadSafetyData();
      safetyData.current = data;
      addOptimizedHeatmapLayer(data);
      addTouristMarkers(tourists);
      
      // Start animation
      animateTourists();
    });

    return () => {
      if (animationRef.current) {
        clearTimeout(animationRef.current);
      }
      map.current?.remove();
    };
  }, [center]);

  // Layer visibility controller
  const toggleLayer = useCallback(() => {
    if (!map.current) return;

    const nextLayer = currentLayer === 'heatmap' ? 'points' : 
                     currentLayer === 'points' ? 'both' : 'heatmap';
    
    setCurrentLayer(nextLayer);

    // Update layer visibility
    const heatmapVisibility = nextLayer === 'points' ? 'none' : 'visible';
    const pointsVisibility = nextLayer === 'heatmap' ? 'none' : 'visible';

    map.current.setLayoutProperty('safety-heatmap', 'visibility', heatmapVisibility);
    map.current.setLayoutProperty('safety-points', 'visibility', pointsVisibility);
  }, [currentLayer]);

  const toggleAnimation = useCallback(() => {
    setIsAnimating(prev => {
      if (!prev) {
        animateTourists();
      } else if (animationRef.current) {
        clearTimeout(animationRef.current);
      }
      return !prev;
    });
  }, [animateTourists]);

  const resetView = useCallback(() => {
    if (!map.current) return;
    map.current.flyTo({  });
  }, [center]);

  return (
    <div className="relative w-full h-full">
      {/* Map Container */}
      <div ref={mapElement} className="w-full h-full rounded-lg overflow-hidden" />
      
      {/* Control Panel */}
      <div className="absolute top-4 left-4 space-y-2">
        <Card className="p-3 bg-white/95 backdrop-blur-sm shadow-lg">
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={toggleAnimation}
              className="h-8"
            >
              {isAnimating ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={toggleLayer}
              className="h-8"
            >
              <Layers className="w-4 h-4 mr-1" />
              {currentLayer}
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={resetView}
              className="h-8"
            >
              <RotateCcw className="w-4 h-4" />
            </Button>
          </div>
        </Card>
      </div>

      {/* Statistics Panel */}
      <div className="absolute top-4 right-4">
        <Card className="p-4 bg-white/95 backdrop-blur-sm shadow-lg min-w-[280px]">
          <h3 className="font-semibold text-lg mb-3 flex items-center gap-2">
            <Shield className="w-5 h-5 text-blue-600" />
            Live Statistics
          </h3>
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">{stats.safeTourists}</div>
              <div className="text-xs text-gray-500">Safe</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-amber-600">{stats.warningTourists}</div>
              <div className="text-xs text-gray-500">Warning</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-600">{stats.dangerTourists}</div>
              <div className="text-xs text-gray-500">Danger</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">{stats.avgSafetyScore}</div>
              <div className="text-xs text-gray-500">Avg Score</div>
            </div>
          </div>
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-600">Total Tourists:</span>
            <Badge variant="secondary">{stats.totalTourists}</Badge>
          </div>
        </Card>
      </div>

      {/* Legend */}
      <div className="absolute bottom-4 right-4">
        <Card className="p-4 bg-white/95 backdrop-blur-sm shadow-lg">
          <h3 className="text-sm font-semibold mb-3">Safety Score Legend</h3>
          <div className="space-y-2">
            {[
              { range: '80-100', label: 'Very Safe', color: '#10B981' },
              { range: '60-79', label: 'Safe', color: '#F59E0B' },
              { range: '40-59', label: 'Moderate Risk', color: '#F97316' },
              { range: '0-39', label: 'High Risk', color: '#EF4444' },
            ].map(({ range, label, color }) => (
              <div key={range} className="flex items-center space-x-2">
                <div 
                  className="w-4 h-4 rounded-full shadow-inner border border-white/50" 
                  style={{ backgroundColor: color }}
                />
                <span className="text-xs text-gray-700">{label} ({range})</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
}
