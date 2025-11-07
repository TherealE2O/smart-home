# Design Document

## Overview

The Smart Home 3D Website is an interactive web application built with Godot 4.x that demonstrates smart home capabilities through an immersive 3D experience. Users can drive through a property, explore a smart home, interact with various IoT devices, view automation history, and create custom automations using a visual node-based editor.

The application will be exported as a Godot web build (HTML5/WebAssembly) and run directly in modern web browsers without plugins.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Web Browser (Client)                     │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Godot Web Export (WASM/WebGL)               │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │            Scene Management Layer               │  │  │
│  │  │  - Main Menu Scene                              │  │  │
│  │  │  - Exterior/Driving Scene                       │  │  │
│  │  │  - Interior Exploration Scene                   │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Smart Device Management System          │  │  │
│  │  │  - Device Registry                              │  │  │
│  │  │  - State Manager                                │  │  │
│  │  │  - Interaction Handler                          │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Automation Engine                       │  │  │
│  │  │  - Rule Evaluator                               │  │  │
│  │  │  - History Manager                              │  │  │
│  │  │  - Visual Editor Controller                     │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │              UI System                          │  │  │
│  │  │  - HUD/Overlay                                  │  │  │
│  │  │  - Device Control Panels                        │  │  │
│  │  │  - Visual Automation Editor                     │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- **Engine**: Godot 4.x (GDScript)
- **Export Target**: HTML5/WebAssembly with WebGL 2.0
- **3D Rendering**: Godot's built-in 3D renderer
- **UI Framework**: Godot's Control nodes and CanvasLayer
- **State Management**: Custom singleton autoload scripts
- **Data Persistence**: Browser LocalStorage via JavaScript bridge

## Components and Interfaces

### 1. Scene Management System

**Purpose**: Manages transitions between different areas of the experience.

**Scenes**:
- `MainMenu.tscn`: Entry point with start button and instructions
- `ExteriorScene.tscn`: Drivable area with gate and garage
- `InteriorScene.tscn`: Explorable smart home interior
- `AutomationEditor.tscn`: Visual automation creation interface

**Scene Manager (Singleton)**:
```gdscript
# SceneManager.gd
extends Node

signal scene_changed(scene_name: String)

func change_scene(scene_path: String) -> void
func get_current_scene() -> Node
func reload_current_scene() -> void
```

### 2. Smart Device System

**Base Device Class**:
```gdscript
# SmartDevice.gd
class_name SmartDevice
extends Node3D

signal state_changed(device_id: String, new_state: Dictionary)
signal interaction_requested(device: SmartDevice)

var device_id: String
var device_name: String
var device_type: String  # "light", "door", "window", etc.
var current_state: Dictionary = {}
var is_interactable: bool = true

func set_state(new_state: Dictionary) -> void
func get_state() -> Dictionary
func toggle() -> void
func _on_input_event(camera, event, position, normal, shape_idx) -> void
```

**Device Types** (inherit from SmartDevice):
- `SmartLight.gd`: Controls OmniLight3D, state: {on: bool, brightness: float}
- `SmartDoor.gd`: Animates door rotation, state: {open: bool, locked: bool}
- `SmartWindow.gd`: Animates window position, state: {open: bool, position: float}
- `SmartBlind.gd`: Animates blind height, state: {position: float}
- `SmartTV.gd`: Changes material/texture, state: {on: bool, channel: int}
- `SmartAC.gd`: Visual effects, state: {on: bool, temperature: float, mode: String}
- `SmartHeater.gd`: Visual effects, state: {on: bool, temperature: float}
- `SmartWaterPump.gd`: Animation/particles, state: {on: bool, flow_rate: float}
- `SmartWaterTank.gd`: Visual water level, state: {level: float}
- `SmartTap.gd`: Water particle effect, state: {on: bool, flow_rate: float}
- `SmartGate.gd`: Sliding/swinging animation, state: {open: bool}
- `SmartGarage.gd`: Door animation, state: {open: bool}

**Device Registry (Singleton)**:
```gdscript
# DeviceRegistry.gd
extends Node

var devices: Dictionary = {}  # device_id -> SmartDevice

func register_device(device: SmartDevice) -> void
func unregister_device(device_id: String) -> void
func get_device(device_id: String) -> SmartDevice
func get_devices_by_type(device_type: String) -> Array[SmartDevice]
func get_all_devices() -> Array[SmartDevice]
```

### 3. Vehicle Controller

**Purpose**: Handles driving mechanics in the exterior scene.

```gdscript
# VehicleController.gd
extends VehicleBody3D

@export var max_speed: float = 20.0
@export var acceleration: float = 10.0
@export var steering_limit: float = 0.5

var current_speed: float = 0.0

func _physics_process(delta: float) -> void
func _handle_input() -> void
func _check_proximity_triggers() -> void  # For gate/garage opening
```

### 4. Camera System

**Purpose**: Manages different camera modes and transitions.

```gdscript
# CameraManager.gd
extends Node

enum CameraMode { VEHICLE, FREE_EXPLORE, DEVICE_FOCUS, EDITOR }

var current_mode: CameraMode
var active_camera: Camera3D

func set_camera_mode(mode: CameraMode) -> void
func focus_on_device(device: SmartDevice) -> void
func enable_free_look() -> void
```

**Camera Types**:
- `VehicleCamera`: Follows vehicle with spring arm
- `ExploreCamera`: Free-roaming with WASD + mouse look
- `FocusCamera`: Smooth transition to focus on specific devices
- `EditorCamera`: Fixed orthographic or isometric for automation editor

### 5. Automation System

**Automation Data Model**:
```gdscript
# Automation.gd
class_name Automation
extends Resource

var automation_id: String
var automation_name: String
var trigger: AutomationTrigger
var conditions: Array[AutomationCondition]
var actions: Array[AutomationAction]
var is_enabled: bool = true
var created_timestamp: int

func evaluate() -> bool
func execute() -> void
```

**Trigger Types**:
```gdscript
# AutomationTrigger.gd
class_name AutomationTrigger
extends Resource

enum TriggerType { TIME, DEVICE_STATE, MANUAL }

var trigger_type: TriggerType
var parameters: Dictionary
# TIME: {hour: int, minute: int, days: Array}
# DEVICE_STATE: {device_id: String, state_key: String, value: Variant}
```

**Action Types**:
```gdscript
# AutomationAction.gd
class_name AutomationAction
extends Resource

var target_device_id: String
var action_type: String  # "set_state", "toggle", "animate"
var parameters: Dictionary

func execute() -> void
```

**Automation Engine (Singleton)**:
```gdscript
# AutomationEngine.gd
extends Node

var active_automations: Array[Automation] = []
var automation_history: Array[AutomationHistoryEntry] = []

func add_automation(automation: Automation) -> void
func remove_automation(automation_id: String) -> void
func evaluate_automations() -> void  # Called every frame or on events
func execute_automation(automation: Automation) -> void
func test_automation(automation: Automation) -> void
func get_history(limit: int = 10) -> Array[AutomationHistoryEntry]
```

**History Entry**:
```gdscript
# AutomationHistoryEntry.gd
class_name AutomationHistoryEntry
extends Resource

var automation_id: String
var automation_name: String
var timestamp: int
var trigger_reason: String
var actions_performed: Array[Dictionary]
var affected_devices: Array[String]
```

### 6. Visual Automation Editor

**Purpose**: Node-based visual programming interface for creating automations.

**Editor Components**:
- `AutomationEditorUI.tscn`: Main editor scene with GraphEdit
- `TriggerNode.gd`: Visual node representing triggers
- `ActionNode.gd`: Visual node representing actions
- `ConditionNode.gd`: Visual node for conditional logic
- `ConnectionManager.gd`: Handles node connections and validation

**GraphEdit Structure**:
```gdscript
# AutomationEditorUI.gd
extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
@onready var node_palette: VBoxContainer = $NodePalette

var current_automation: Automation

func _ready() -> void
func add_trigger_node(trigger_type: String) -> void
func add_action_node(device_id: String) -> void
func _on_connection_request(from_node, from_port, to_node, to_port) -> void
func save_automation() -> void
func load_automation(automation: Automation) -> void
func test_current_automation() -> void
```

### 7. UI System

**HUD Components**:
- `MainHUD.tscn`: Persistent overlay with mode switcher, minimap, help
- `DeviceControlPanel.tscn`: Popup panel for device interaction
- `AutomationHistoryPanel.tscn`: List view of past automations
- `TutorialOverlay.tscn`: First-time user guidance

**Device Control Panel**:
```gdscript
# DeviceControlPanel.gd
extends Panel

var current_device: SmartDevice

func show_device(device: SmartDevice) -> void
func _populate_controls() -> void
func _on_control_changed(control_name: String, value: Variant) -> void
```

### 8. Interaction System

**Purpose**: Handles raycasting and device selection.

```gdscript
# InteractionManager.gd
extends Node

var camera: Camera3D
var raycast_length: float = 100.0
var highlighted_device: SmartDevice = null

func _physics_process(delta: float) -> void
func _perform_raycast() -> void
func _highlight_device(device: SmartDevice) -> void
func _unhighlight_device() -> void
func _on_click() -> void
```

## Data Models

### Device State Schema

Each device maintains a state dictionary with device-specific keys:

```json
{
  "light": {
    "on": true,
    "brightness": 0.8,
    "color": "#FFFFFF"
  },
  "door": {
    "open": false,
    "locked": true
  },
  "ac": {
    "on": true,
    "temperature": 22.5,
    "mode": "cool",
    "fan_speed": 2
  },
  "water_tank": {
    "level": 0.75,
    "capacity": 1000
  }
}
```

### Automation Schema

```json
{
  "automation_id": "auto_001",
  "automation_name": "Evening Lights",
  "trigger": {
    "type": "TIME",
    "parameters": {
      "hour": 18,
      "minute": 0
    }
  },
  "conditions": [],
  "actions": [
    {
      "target_device_id": "light_living_room",
      "action_type": "set_state",
      "parameters": {
        "on": true,
        "brightness": 0.6
      }
    }
  ],
  "is_enabled": true
}
```

### Persistence Schema (LocalStorage)

```json
{
  "user_automations": [],
  "device_states": {},
  "tutorial_completed": false,
  "settings": {
    "graphics_quality": "medium",
    "audio_enabled": true
  }
}
```

## Error Handling

### Device Interaction Errors

- **Device Not Found**: Log warning, show user-friendly message
- **Invalid State**: Clamp values to valid ranges, log warning
- **Animation Conflict**: Queue state changes, prevent simultaneous conflicting animations

### Automation Errors

- **Invalid Trigger**: Prevent automation save, highlight error in editor
- **Missing Device**: Skip action, log to history with error flag
- **Circular Dependencies**: Detect during save, prevent creation
- **Execution Timeout**: Cancel automation after 5 seconds, log error

### Web Export Errors

- **WebGL Not Supported**: Show fallback message with browser requirements
- **Memory Limit**: Reduce texture quality, disable particle effects
- **Loading Failure**: Show retry button, log error to console

### Error Handling Pattern

```gdscript
# Example error handling
func execute_device_action(device_id: String, action: Dictionary) -> Result:
    var device = DeviceRegistry.get_device(device_id)
    if device == null:
        push_error("Device not found: " + device_id)
        return Result.error("Device not found")
    
    if not device.is_interactable:
        push_warning("Device not interactable: " + device_id)
        return Result.error("Device locked")
    
    device.set_state(action.parameters)
    return Result.ok()
```

## Testing Strategy

### Unit Testing

**Device State Management**:
- Test state transitions for each device type
- Verify state validation and clamping
- Test device registration/unregistration

**Automation Logic**:
- Test trigger evaluation with various conditions
- Test action execution and rollback
- Test automation serialization/deserialization

**Tools**: GdUnit4 or Gut (Godot Unit Testing)

### Integration Testing

**Scene Transitions**:
- Test smooth transitions between exterior and interior
- Verify device persistence across scene changes
- Test camera mode switching

**Automation Execution**:
- Test end-to-end automation creation and execution
- Verify history recording
- Test automation replay functionality

### Visual/Manual Testing

**3D Interaction**:
- Verify vehicle controls feel responsive
- Check device highlighting and selection
- Test camera controls in all modes
- Verify visual feedback for all device states

**UI/UX**:
- Test automation editor usability
- Verify all panels and overlays display correctly
- Test on different screen resolutions
- Check mobile/touch compatibility (if supported)

**Performance**:
- Monitor FPS in different scenes
- Test with maximum number of active automations
- Verify memory usage stays within browser limits
- Test loading times for initial scene

### Browser Compatibility Testing

Test on:
- Chrome/Edge (Chromium)
- Firefox
- Safari (WebKit)

Verify:
- WebGL 2.0 rendering
- WebAssembly execution
- LocalStorage access
- Input handling (keyboard, mouse, touch)

### Automation Testing Approach

**Test Automation Creation**:
1. Create sample automations programmatically
2. Verify they appear in editor correctly
3. Test execution and verify expected device states
4. Check history entries are created

**Test Visual Editor**:
1. Add nodes via palette
2. Create connections
3. Save and reload
4. Verify generated automation data structure

## Performance Considerations

### 3D Optimization

- Use LOD (Level of Detail) for complex models
- Implement occlusion culling for interior scenes
- Limit active particle systems to 5 concurrent
- Use baked lighting where possible
- Target 30-60 FPS on mid-range hardware

### Memory Management

- Unload unused scenes aggressively
- Use object pooling for particle effects
- Limit texture sizes (max 2048x2048)
- Compress meshes and textures
- Target <200MB total memory usage

### Web Export Optimization

- Enable Godot's web export compression
- Use streaming for larger assets
- Implement progressive loading with splash screen
- Minimize GDScript execution in _process()
- Use physics_process only when necessary

## Placeholder Model Specifications

All placeholder models should follow these conventions:

### Model Requirements

- **Format**: GLTF 2.0 (.glb or .gltf)
- **Scale**: 1 unit = 1 meter in Godot
- **Origin**: Center bottom for floor-standing objects, center for wall-mounted
- **Orientation**: Forward = -Z axis, Up = Y axis
- **Polycount**: <1000 triangles per model

### Naming Convention

```
models/
  ├── devices/
  │   ├── light_bulb.glb
  │   ├── tv.glb
  │   ├── ac_unit.glb
  │   ├── heater.glb
  │   ├── water_pump.glb
  │   ├── water_tank.glb
  │   ├── tap.glb
  │   ├── door.glb
  │   ├── window.glb
  │   └── blind.glb
  ├── exterior/
  │   ├── gate.glb
  │   ├── garage_door.glb
  │   └── vehicle.glb
  └── structure/
      ├── house_exterior.glb
      └── house_interior.glb
```

### Attachment Points

Each device model should include named empty nodes for:
- `InteractionPoint`: Where raycast hits for selection
- `EffectSpawn`: Where particles/effects spawn
- `LabelAnchor`: Where floating labels appear

## Deployment

### Build Configuration

```
Export Preset: HTML5
Export Path: build/web/index.html
Features: WebGL 2.0, Threads (if supported)
Texture Format: VRAM Compressed
Compression: Enabled
Memory Size: 256 MB (adjustable)
```

### Hosting Requirements

- Static file hosting (no server-side logic needed)
- HTTPS recommended for full WebAssembly features
- CORS headers configured for asset loading
- Gzip/Brotli compression enabled

### File Structure

```
build/web/
  ├── index.html
  ├── index.js
  ├── index.wasm
  ├── index.pck (game data)
  └── index.png (icon)
```

## Future Enhancements

- Multi-user collaboration (WebRTC)
- Voice control integration (Web Speech API)
- VR support (WebXR)
- Mobile touch controls optimization
- Cloud save/sync for automations
- Analytics dashboard for automation effectiveness
- Integration with real smart home APIs (demo mode)
