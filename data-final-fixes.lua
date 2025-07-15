
---------------------------------------------------------------------------------------------------
---> data-final-fixes.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local ThisMOD = {}

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function ThisMOD.Start()
    --- Valores de la referencia
    ThisMOD.setSetting()

    --- Entidades a afectar
    ThisMOD.BuildInfo()

    --- Ingredientes a usar
    ThisMOD.BuildIngredients()

    --- Crear los nuevos prototipos
    for _, Type in pairs(ThisMOD.Info) do
        for _, Space in pairs(Type) do
            ThisMOD.CreateRecipe(Space)
            ThisMOD.CreateItem(Space)
            ThisMOD.CreateEntity(Space)
        end
    end
end

--- Valores de la referencia
function ThisMOD.setSetting()
    --- Otros valores
    ThisMOD.Prefix         = "zzzYAIM0425-0400-"
    ThisMOD.name           = "robots-with-unlimited-electricity"

    --- Indicador
    ThisMOD.localised_name = { "entity-description." .. ThisMOD.Prefix .. "with-unlimited-electricity" }

    --- Información de referencia
    ThisMOD.Info           = {}
    ThisMOD.Ingredients    = {}
    ThisMOD.oldItemName    = {}

    --- Referencia
    ThisMOD.Types          = {}
    table.insert(ThisMOD.Types, "construction-robot")
    table.insert(ThisMOD.Types, "logistic-robot")

    --- Indicador de mod
    ThisMOD.Indicator       = {
        icon  = data.raw["virtual-signal"]["signal-battery-full"].icon,
        shift = { 14, -4 },
        scale = 0.15
    }
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Crear ThisMOD.Ingredients
function ThisMOD.BuildIngredients()
    --- Ingredientes a usar
    ThisMOD.oldItemName = {
        ThisMOD.getBattery(),
        ThisMOD.getSolarPanel()
    }

    --- Dar el formaro deseado
    for _, value in pairs(ThisMOD.oldItemName) do
        table.insert(
            ThisMOD.Ingredients,
            {
                type   = "item",
                name   = value,
                amount = 3
            }
        )
    end
end

--- Buscar los ingredientes a usar
function ThisMOD.getBattery()
    local equipment = { energy_source = { buffer_capacity = "1j" } }
    local now = GPrefix.getNumber(equipment.energy_source.buffer_capacity)
    for _, Equipment in pairs(GPrefix.Equipments) do
        if Equipment.type == "battery-equipment" then
            local next = GPrefix.getNumber(Equipment.energy_source.buffer_capacity)
            if next > now then
                equipment = Equipment
                now = next
            end
        end
    end
    return equipment.name
end

function ThisMOD.getSolarPanel()
    local equipment = { power = "1j" }
    local now = GPrefix.getNumber(equipment.power)
    for _, Equipment in pairs(GPrefix.Equipments) do
        if Equipment.type == "solar-panel-equipment" then
            local next = GPrefix.getNumber(Equipment.power)
            if next > now then
                equipment = Equipment
                now = next
            end
        end
    end
    return equipment.name
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Información de referencia
function ThisMOD.BuildInfo()
    for _, Type in pairs(ThisMOD.Types) do
        ThisMOD.Info[Type] = ThisMOD.Info[Type] or {}
        for _, Robot in pairs(data.raw[Type]) do
            --- Validación
            local Flag = Robot.minable and not Robot.hidden
            Flag = Flag and Robot.minable.results

            --- Guardar toda la información
            if Flag then
                local item = Robot.minable.results[1].name
                local Space = ThisMOD.Info[Type][Robot.name] or {}
                ThisMOD.Info[Type][Robot.name] = Space

                Space.item = GPrefix.Items[item]
                Space.entity = Robot
                Space.recipe = GPrefix.Recipes[item][1]
            end
        end
    end
end

--- Crear las recetas
function ThisMOD.CreateRecipe(space)
    --- Duplicar la receta
    local recipe   = util.copy(space.recipe)

    --- Actualizar propiedades
    recipe.name    = GPrefix.delete_prefix(recipe.name)
    recipe.name    = ThisMOD.Prefix .. recipe.name

    recipe.icons   = util.copy(space.item.icons)
    recipe.enabled = false
    table.insert(recipe.icons, ThisMOD.Indicator)

    local Order  = tonumber(recipe.order) + 2
    recipe.order = GPrefix.pad_left(#recipe.order, Order)

    recipe.main_product = nil

    recipe.ingredients  = util.copy(ThisMOD.Ingredients)
    table.insert(
        recipe.ingredients,
        {
            type   = "item",
            name   = space.item.name,
            amount = 1
        }
    )

    recipe.results = { {
        type = "item",
        name = ThisMOD.Prefix .. GPrefix.delete_prefix(space.item.name),
        amount = 1
    } }

    --- Crear el prototipo
    GPrefix.addDataRaw({ recipe })

    --- Agregar las recetas en la tecnologia
    for _, oldItemName in pairs(ThisMOD.oldItemName) do
        GPrefix.addRecipeToTechnology(oldItemName, nil, recipe)
        if not recipe.enabled then break end
    end
end

--- Crear los objetos
function ThisMOD.CreateItem(space)
    --- Crear la entidad
    local item        = util.copy(space.item)

    item.name         = ThisMOD.Prefix .. GPrefix.delete_prefix(item.name)
    item.place_result = ThisMOD.Prefix .. GPrefix.delete_prefix(item.place_result)

    local Order       = tonumber(item.order) + 2
    item.order        = GPrefix.pad_left(#item.order, Order)

    --- Agregar el indicador
    table.insert(item.icons, ThisMOD.Indicator)

    --- Crear el prototipo
    GPrefix.addDataRaw({ item })
end

--- Crear las entidades
function ThisMOD.CreateEntity(space)
    --- Crear la entidad
    local robot  = util.copy(space.entity)
    local result = robot.minable.results[1]

    --- Actualizar propiedades
    robot.name   = ThisMOD.Prefix .. GPrefix.delete_prefix(robot.name)
    result.name  = ThisMOD.Prefix .. GPrefix.delete_prefix(result.name)

    --- Agregar el indicador
    table.insert(robot.icons, ThisMOD.Indicator)

    --- Retirar el gasto de energia
    robot.energy_per_tick = nil
    robot.energy_per_move = nil
    robot.max_energy = "1J"

    --- Crear el prototipo
    GPrefix.addDataRaw({ robot })
end

---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
ThisMOD.Start()

---------------------------------------------------------------------------------------------------



--[[

    --- Retirar el gasto de energia
    robot.energy_per_tick = nil
    robot.energy_per_move = nil
    robot.max_energy = "1J"

    --- Dividir el nombre por guiones
    local id, name = space.tech.name:match(GPrefix.name_pattern .. "(.+)")
    if id then
        if id == "0300" then
            table.insert(
                Tech.prerequisites,
                GPrefix.name .. "-" ..
                This_MOD.id .. "-" ..
                name
            )
        end
    end

]]