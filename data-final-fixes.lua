---------------------------------------------------------------------------------------------------
---> data-final-fixes.lua <---
---------------------------------------------------------------------------------------------------

--- Contenedor de funciones y datos usados
--- unicamente en este archivo
local This_MOD = {}

---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
function This_MOD.start()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Obtener información desde el nombre de MOD
    GPrefix.split_name_folder(This_MOD)

    --- Valores de la referencia
    This_MOD.setting_mod()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Entidades a afectar
    This_MOD.build_info()

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear los nuevos prototipos
    for _, type in pairs(This_MOD.info) do
        for _, space in pairs(type) do
            This_MOD.create_recipe(space)
            This_MOD.create_item(space)
            This_MOD.create_entity(space)
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Valores de la referencia
function This_MOD.setting_mod()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Información de referencia
    This_MOD.info = {}
    This_MOD.types = { "construction-robot", "logistic-robot" }
    This_MOD.resistances = {}

    --- Indicadores del MOD
    local Indicator = data.raw["virtual-signal"]["signal-battery-full"].icons[1].icon

    This_MOD.icon = {
        tech = { icon = Indicator, scale = 0.50, shift = { 50, 0 } },
        tech_bg = { icon = GPrefix.color.black, scale = 0.50, shift = { 50, 0 } },
        other = { icon = Indicator, scale = 0.15, shift = { 12, 0 } },
        other_bg = { icon = GPrefix.color.black, scale = 0.15, shift = { 12, 0 } }
    }

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Información de referencia
function This_MOD.build_info()
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    ---> Cargar las entidades a duplicar
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    for _, type in pairs(This_MOD.types) do
        for _, robot in pairs(data.raw[type]) do
            repeat
                --- Validación
                if robot.hidden then break end
                local Item = GPrefix.get_item_create_entity(robot)
                if not Item then break end

                --- Crear el espacio para la entidad
                This_MOD.info[type] = This_MOD.info[type] or {}
                local Space = This_MOD.info[type][robot.name] or {}
                This_MOD.info[type][robot.name] = Space

                --- Guardar la información
                Space.item = Item
                Space.entity = robot
                Space.recipe = GPrefix.recipes[Item.name][1]
                Space.tech = GPrefix.get_technology(Space.recipe)
            until true
        end
    end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Crear las recetas
function This_MOD.create_recipe(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Duplicar la receta
    local Recipe = util.copy(space.recipe)

    --- Actualizar propiedades
    Recipe.name = GPrefix.delete_prefix(space.recipe.name)
    Recipe.name = This_MOD.prefix .. Recipe.name

    Recipe.main_product = nil
    Recipe.energy_required = 15 * 60

    Recipe.icons = util.copy(space.item.icons)
    table.insert(Recipe.icons, This_MOD.icon.other_bg)
    table.insert(Recipe.icons, This_MOD.icon.other)

    local Order = tonumber(Recipe.order) + 1
    Recipe.order = GPrefix.pad_left_zeros(#Recipe.order, Order)

    Recipe.ingredients = { {
        type = "item",
        name = space.item.name,
        amount = 1
    } }

    if GPrefix.has_id(space.item.name, "0300") then
        table.insert(
            Recipe.ingredients,
            {
                type = "item",
                name = string.gsub(
                    space.item.name,
                    "%-%d%d%d%d%-",
                    "-" .. This_MOD.id .. "-"
                ),
                amount = 1
            }
        )
    end

    Recipe.results = { {
        type = "item",
        name = This_MOD.prefix .. GPrefix.delete_prefix(space.item.name),
        amount = 1
    } }

    --- Agregar la receta a la tecnología
    This_MOD.create_tech(space, Recipe)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Crear los objetos
function This_MOD.create_item(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear la entidad
    local Item = util.copy(space.item)

    Item.name = This_MOD.prefix .. GPrefix.delete_prefix(space.item.name)
    Item.place_result = This_MOD.prefix .. GPrefix.delete_prefix(space.item.place_result)

    local Order = tonumber(Item.order) + 1
    Item.order = GPrefix.pad_left_zeros(#Item.order, Order)

    --- Agregar el indicador
    table.insert(Item.icons, This_MOD.icon.other_bg)
    table.insert(Item.icons, This_MOD.icon.other)

    --- Crear el prototipo
    GPrefix.extend(Item)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

--- Crear las entidades
function This_MOD.create_entity(space)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Crear la entidad
    local Entity = util.copy(space.entity)
    local Result = GPrefix.get_table(Entity.minable.results, "name", space.item.name)

    --- Actualizar propiedades
    Entity.name = This_MOD.prefix .. GPrefix.delete_prefix(space.entity.name)
    Result.name = This_MOD.prefix .. GPrefix.delete_prefix(Result.name)

    --- Agregar el indicador
    table.insert(Entity.icons, This_MOD.icon.other_bg)
    table.insert(Entity.icons, This_MOD.icon.other)

    --- Retirar el gasto de energia
    Entity.energy_per_tick = nil
    Entity.energy_per_move = nil
    Entity.max_energy = "1J"

    --- Crear el prototipo
    GPrefix.extend(Entity)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------

--- Crear las tecnologías
function This_MOD.create_tech(space, new_recipe)
    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Validación
    if not space.tech then return end

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---

    --- Varios prerequisitos
    local Info
    if GPrefix.has_id(space.tech.name, "0300") then
        Info = { prerequisites = { space.tech.name } }
        local Name = string.gsub(
            space.tech.name,
            "%-%d%d%d%d%-",
            "-" .. This_MOD.id .. "-"
        )
        table.insert(Info.prerequisites, Name)
    end

    --- Duplicar la tecnología
    local Tech = GPrefix.create_tech(This_MOD.prefix, space.tech, new_recipe, Info)

    --- Agregar indicadores a la tecnología
    table.insert(Tech.icons, This_MOD.icon.tech_bg)
    table.insert(Tech.icons, This_MOD.icon.tech)

    --- --- --- --- --- --- --- --- --- --- --- --- --- ---
end

---------------------------------------------------------------------------------------------------





---------------------------------------------------------------------------------------------------

--- Iniciar el modulo
This_MOD.start()

---------------------------------------------------------------------------------------------------
