-- Examinable interface
-- Provides a standardized way to get information about game objects for examination mode

local Examinable = {}

-- Standard method to get examination information from any game object
-- Returns a table with standardized fields for the UI to display
function Examinable:getExaminationInfo()
    return {
        name = self.name or "Unknown",
        description = self.description or "",
        properties = self.properties or {},
        image = self.infoscreenImage,
        flavorText = self.flavorText or "You see nothing special."
    }
end

-- Mixin function to add examinable functionality to any class
function Examinable.mixin(class)
    class.getExaminationInfo = Examinable.getExaminationInfo
end

return Examinable
