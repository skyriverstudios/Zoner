--[[
================================================================================
README: Zone Detection System Enums
================================================================================

This README provides a complete list of Enums used in the Zone Detection System,
along with detailed descriptions of each Enum, their values, and when to use them.

--------------------------------------------------------------------------------
Enum: DetectionMethod
Specifies the detection method used to balance efficiency and accuracy.

Values:
    Automatic   -- Automatically selects the most appropriate method based on 
                 -- the zone’s shape, bounds, and target complexity. Uses efficient 
                 -- methods for simple shapes, like PointInPart, and more complex 
                 -- methods for irregular shapes as needed.
                        
    Efficient   -- Prioritizes speed and performance using fast methods like 
                 -- PointInPart. Ideal for simple shapes or scenarios where high 
                 -- accuracy is not required.
                        
    Simple      -- Balances between efficiency and accuracy with methods such as 
                 -- PartsInBox or PartsInSphere. Useful for moderately complex 
                 -- shapes with a mix of performance and precision.
                        
    Complex     -- Prioritizes accuracy over efficiency, using methods such as 
                 -- GetPartsInPart for complex shapes. This approach is more 
                 -- resource-intensive and ideal for high-precision detection.

--------------------------------------------------------------------------------
Enum: DetectionMode
Defines how precise the detection needs to be for each target within the zone.

Values:
    Full        -- Requires the target to be fully contained within the zone 
                 -- for detection. Best for scenarios where total inclusion 
                 -- is necessary.

    Touch       -- Allows detection if the target is touching or partially 
                 -- overlapping the zone boundary. Suitable for partial entry 
                 -- detection.

    Point       -- Detects based on specific points within the target. This 
                 -- mode is the most efficient and ideal for quick checks or 
                 -- when point-based accuracy is sufficient.

--------------------------------------------------------------------------------
Enum: DetectionCoverage
Defines which part of the target is checked for detection within the zone.

Values:
    Center      -- Only detects the center of the target. Ideal for quick 
                 -- checks or when the center point is the primary indicator 
                 -- of the target’s presence in the zone.

    AllParts    -- Requires all parts of the target to be within the zone. 
                 -- Suitable for complex or multi-part objects that require 
                 -- full containment.

    AnyPart     -- Detects if any part of the target is inside the zone. 
                 -- Useful for quick detection when partial entry of the 
                 -- target is sufficient.

    BoundingBox -- Uses the target’s bounding box for detection. This provides 
                 -- a general area check, useful for larger objects or 
                 -- approximate detection.

--------------------------------------------------------------------------------
Enum: Rate
Determines how frequently internal zone checks are run, balancing resource usage 
and detection speed.

Values:
    Slow        -- Runs zone checks every 1.0 second. Useful for low-priority 
                 -- or resource-saving checks where frequent updates are not 
                 -- necessary.

    Moderate    -- Runs zone checks every 0.5 seconds, providing a balance 
                 -- between performance and responsiveness. Suitable for 
                 -- moderate update needs.

    Fast        -- Runs zone checks every 0.1 second, ideal for more frequent 
                 -- updates, ensuring timely detection but with higher 
                 -- resource use.

    Immediate   -- Runs zone checks continuously with zero delay. Suitable 
                 -- for real-time detection needs, but requires more processing 
                 -- power.

--------------------------------------------------------------------------------
Enum: Execution
Determines the type of processing (Serial or Parallel) used for handling zone checks, 
affecting performance and control.

Values:
    Serial      -- Runs zone checks in a single sequence without using 
                 -- parallel threads. Can be manually stepped through by the 
                 -- user, allowing direct control over the internal logic. 
                 -- Suitable for simpler setups with step-by-step control.

    Parallel    -- Runs zone checks efficiently in separate threads, reducing 
                 -- the workload on the main thread. Ideal for setups with 
                 -- multiple zones, as it allows concurrent processing to 
                 -- manage complex zones with minimal impact on performance.

--------------------------------------------------------------------------------
Enum: Simulation
Defines when the detection or simulation checks are executed in relation to 
the simulation or rendering steps.

Values:
    PostSimulation -- Executes after the physics simulation step. Useful for 
                     handling tasks that rely on finalized simulation results 
                     or need to account for physics calculations.

    PreSimulation  -- Executes before the physics simulation step. Ideal for 
                     preparing or adjusting objects prior to simulation, such 
                     as setting forces or updating physics-related states.

    PreRender      -- Executes before the rendering step. Used for preparing 
                     objects or settings that need to be finalized just 
                     before being drawn on the screen.

================================================================================
]]--