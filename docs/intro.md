---
title: ZoneConfig
---

# ZoneConfig Overview

`ZoneConfig` defines how a Zone behaves at runtime—how it detects objects, how often it updates, and what simulation or execution model it uses.  
It combines several configurable Enums to control performance, accuracy, and simulation timing.  

If any field is left **blank**, the system automatically applies the **default configuration** below.

---

## Default Zone Configuration

```lua
-- Create a default Configs table constant:
local DEFAULT_ZONE_CONFIG = {
	DetectionCoverage = Enums.DetectionCoverage.Center,
	DetectionMethod   = Enums.DetectionMethod.Automatic,
	DetectionMode     = Enums.DetectionMode.Point,
	Simulation        = Enums.Simulation.PostSimulation,
	Execution         = Enums.Execution.Parallel,
	Bounds            = Enums.Bounds.Automatic,
	Rate              = Enums.Rate.Fast,

	NoZonePartPropertyListening = false,
	NoZonePartAddedListening    = false,
	ManualStepping              = false,
}
```

## Detection Settings

### DetectionMethod
Determines the algorithm used to detect objects within the Zone volume.

| Mode | Description |
|------|--------------|
| **Automatic** | Automatically selects the most suitable detection method based on the Zone container's shape and complexity. |
| **Efficient** | Fastest option. Uses raw CFrame and Size math to test inclusion in the Zone bounds. Ideal for simple box/sphere volumes. |
| **Simple** | Balanced mode using `GetPartBoundsInBox` or `GetPartBoundsInRadius` under the hood. Provides solid accuracy at modest performance cost. |
| **Complex** | Highest accuracy. Uses detailed `GetPartsInPart` or mesh-aware tests. May create placeholder parts if the ZoneContainer is empty. |

---

### DetectionMode
Controls *how much* of a target must be inside the Zone to count as "within."

| Mode | Description |
|------|--------------|
| **Full** | The entire target must be inside or outside before triggering entrance or exit. |
| **Touch** | Any overlap or intersection with the Zone boundary counts. (Does **not** use `.Touched` events.) |
| **Point** | Only representative points (e.g., center or probes) need to be inside. Extremely fast, works best with `Efficient` detection. |

---

### DetectionCoverage
Specifies which parts of a target are considered during detection.

| Mode | Description |
|------|--------------|
| **Center** | Only checks the object’s central point. Very fast, math-only. |
| **AllParts** | All tracked parts must satisfy the `DetectionMode`. Strictest and slowest option. |
| **AnyPart** | At least one part must satisfy `DetectionMode`. More lenient and performant. |

---

### Detection Extras
**Note:**
The following optional fields are not automatically filled and remain `nil` unless explicitly defined:

| Field | Description |
|------|--------------|
| **ExitDetectionMode** | The *DetectionMode* used for checking what is trying to **Exit** the Zone. |
| **ExitDetectionCoverage** | The *DetectionCoverage* used for checking what is trying to **Exit** the Zone. |
| **EnterDetectionMode** | The *DetectionMode* used for checking what is trying to **Enter** the Zone. |
| **EnterDetectionCoverage** | The *DetectionCoverage* used for checking what is trying to **Enter** the Zone. |

## Execution & Simulation Behavior

### Execution
Determines how zone evaluation logic is executed internally.

| Mode | Description |
|------|--------------|
| **Serial** | Runs all checks on a single thread. Allows manual stepping via `Zone:Step(...)` when `ManualStepping = true`. |
| **Parallel** | Uses Roblox Actors for concurrent evaluation. Runs automatically and scales best for many Zones. Manual stepping not supported. |

---

### Simulation
Specifies which stage of the Roblox simulation pipeline the Zone runs during.

| Mode | Description |
|------|--------------|
| **PostSimulation** | Executes after physics updates. Good for effects based on final part positions. |
| **PreSimulation** | Runs before physics; ideal for setting up constraints or forces. |
| **PreRender** | Runs before rendering (client-side only). On the server, coerced to `PostSimulation`. |

---

## Bounds Configuration

### Bounds
Defines how the Zone determines its bounding volume.

| Mode | Description |
|------|--------------|
| **Automatic** | Auto-selects a bounding model (box, sphere, or per-part) based on container geometry. |
| **BoxExact** | Creates a precise rotated box that fits the ZoneContainer. No instance unless explicitly defined. |
| **BoxVoxel** | Like `BoxExact` but aligns to the voxel grid for grid-based zones. |
| **PerPart** | Evaluates each contained `BasePart` or `{CFrame, Size}` entry individually, combining their bounds to form the Zone. |

---

## Update/Detection Frequency

### Rate
Sets how frequently the Zone evaluates entries, exits, or triggers.  

| Mode | Step Period | Description |
|------|--------------|-------------|
| **Slow** | ≈ 1.0 s | Low-frequency updates; best for large or low-priority zones. |
| **Moderate** | ≈ 0.5 s | Medium-frequency; general-purpose default. |
| **Fast** | ≈ 0.1 s | High-frequency checks for responsive gameplay interactions. |
| **Immediate** | 0 s | Evaluates every frame or heartbeat slice. Continuous mode; most CPU-intensive. |

---

## Event Listening & Manual Stepping

### Rate
Sets how frequently the Zone evaluates entries, exits, or triggers.  

| Property | Type | Default | Description |
|----------|------|-------|-------------|
| **NoZonePartPropertyListening** | boolean | false | Disables automatic property change monitoring on ZoneParts (e.g., Size or CFrame). When true, Zones will not auto-update their bounds. |
| **NoZonePartAddedListening** | boolean | false | Disables automatic updates when ZoneParts are added or removed from a ZoneContainer folder or model. |
| **ManualStepping** | boolean | false | Only valid for `Execution = Serial.` Enables manual stepping via `Zone:Step(DeltaTime)` to control when Zone evaluations occur. |

---

## Example ZoneConfig Usage

```lua
--!strict

-- Require the Zoner Module:
local Zoner = require(script.Parent.Vendor.Zoner)

-- Reference a Part Box BasePart in Workspace to use as a Zone reference:
-- (If enabled, Zoner will automatically update as the ZonePart moves or changes size)
local ZoneBox: BasePart = workspace.Box

-- Define a ZoneConfig table:
-- Any of the following can be left blank, you don’t even need to use one:
local ZoneConfig: Zoner.ZoneConfig = {
	DetectionCoverage = Zoner.Enum.DetectionCoverage.Center;
	DetectionMethod   = Zoner.Enum.DetectionMethod.Efficient;
	DetectionMode     = Zoner.Enum.DetectionMode.Point;

	Simulation = Zoner.Enum.Simulation.PostSimulation;
	Bounds     = Zoner.Enum.Bounds.BoxExact;
	Execution  = Zoner.Enum.Execution.Parallel;
	Rate       = Zoner.Enum.Rate.Immediate;

	NoZonePartPropertyListening = false;
	NoZonePartAddedListening    = false;
	ManualStepping              = false;
}

-- Create the Zone Object using the ZoneBox and ZoneConfig:
local Zone_From_Part: Zoner.Zone = Zoner.New(ZoneBox, ZoneConfig)

```

## Summary

- Any blank field in ZoneConfig defaults to DEFAULT_ZONE_CONFIG.
- Optional fields (Enter/ExitDetectionMode and Coverage) are nil by default.
- Event listening flags allow performance tuning for static zones.
- ManualStepping provides full control for serialized simulation updates.

This configuration gives you precise control over how Zones detect, simulate, and update—all within the Zoner framework.