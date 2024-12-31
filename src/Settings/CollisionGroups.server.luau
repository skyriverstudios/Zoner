
-- Grab the Service:
local PhysicsService = game:GetService('PhysicsService')
-- Register the ZonePart Collision Group:
PhysicsService:RegisterCollisionGroup('Zoner:ZonePart')
PhysicsService:CollisionGroupSetCollidable('Zoner:ZonePart', 'Zoner:ZonePart', false)

-- Clear variable:
PhysicsService = nil :: any;
-- Destroy this Script:
script:Destroy()