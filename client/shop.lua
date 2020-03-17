--[[ Marker loop ]]--
Citizen.CreateThread(function()
    while true do
        local wait = 750
        local coords = GetEntityCoords(PlayerPedId())
        for i=1, #Config.Locations do
            for j=1, #Config.Locations[i]["shelfs"] do
                local pos = Config.Locations[i]["shelfs"][j]
                local dist = GetDistanceBetweenCoords(coords, pos["x"], pos["y"], pos["z"], true)
                if dist <= 5.0 then
                    if dist <= 1.5 then
                        local text = Config.Locales[pos["value"]]
                        if dist <= 1.0 then
                            text = "[E] " .. text
                            if IsControlJustPressed(0, Keys["E"]) then
                                OpenAction(pos, Config.Items[pos["value"]], Config.Locales[pos["value"]])
                        	end
                        end
                        DrawText3D(pos["x"], pos["y"], pos["z"], text)
                    end
                    wait = 5
                    Marker(pos)
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

--[[ Loop for checking if player is too far away, then empty basket ]] --
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if payAmount > 0 then
            for shop = 1, #Config.Locations do
                local blip = Config.Locations[shop]["blip"]
                local dist = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), blip["x"], blip["y"], blip["z"], true)
                if dist <= 20.0 then
                    if dist >= 12.0 then
                        TriggerEvent('notification', 'Marketi terkettin, sepetin bosaltildi.', 1)
                        payAmount = 0
                        Basket = {}
                    end
                end
            end
        end
    end
end)

--[[ Check what to do ]]--
OpenAction = function(action, shelf, text)
    if action["value"] == "checkout" then
        if payAmount > 0 and #Basket then
            CashRegister(text)
        else
            TriggerEvent('notification', 'Sepetinde hicbir sey yok.', 1)
        end
    else
        ShelfMenu(text, shelf)
    end
end

--[[ Cash register menu ]]--
CashRegister = function(titel)
        local elements = {
            {label = '<span style="color:lightgreen; border-bottom: 1px solid lightgreen;">Onayla</span>', value = "yes"},
            {label = 'Tutar: <span style="color:green">$' .. payAmount ..'</span>'},
        }

        for i=1, #Basket do
            local item = Basket[i]
            table.insert(elements, {
                label = '<span style="color:red">*</span> ' .. item["label"] .. ': ' .. item["amount"] .. ' adet',
                value = item["value"],
            })
        end

        ESX.UI.Menu.CloseAll()
        ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'penis',
            {
                title    = "Market - " .. titel,
                align    = 'center',
                elements = elements
            },
            function(data, menu)
            
                if data.current.value == "yes" then
                    menu.close()
                    ESX.UI.Menu.Open(
                        'default', GetCurrentResourceName(), 'penis2',
                        {
                            title    = "Market - Ödeme",
                            align    = 'center',
                            elements = {
                                {label = "Nakitle öde", value = "cash"},
                                {label = "Kredi kartıyla öde", value = "bank"},
                            },
                        },
                        function(data2, menu2)
                            ESX.TriggerServerCallback('99kr-shops:CheckMoney', function(hasMoney)
                                if hasMoney then
                                    TriggerServerEvent('99kr-shops:Cashier', payAmount, Basket, data2.current["value"])
                                    payAmount = 0
                                    Basket = {}
                                    menu2.close()
                                else
                                    TriggerEvent('notification', 'Yeterince paran yok.', 1)
                                end
                            end, payAmount, data2.current["value"])
                        end,
                    function(data2, menu2)
                        menu2.close()
                    end)
                end
            end,
        function(data, menu)
            menu.close()
    end) 
end

--[[ Open shelf menu ]]--
ShelfMenu = function(titel, shelf)
    local elements = {}

    for i=1, #shelf do
        local shelf = shelf[i]
        table.insert(elements, {
            realLabel = shelf["label"],
            label = shelf["label"] .. ' (<span style="color:green">$' .. shelf["price"] .. '</span>)',
            item = shelf["item"],
            price = shelf["price"],
            value = 1, type = 'slider', min = 1, max = 100,
        })
    end
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'penis',
        {
            title    = "Market - " .. titel,
            align    = 'center',
            elements = elements
        },
        function(data, menu)
        
            local alreadyHave, basketItem = CheckBasketItem(data.current.item)
            if alreadyHave then
                basketItem.amount = basketItem["amount"] + data.current.value
            else
                table.insert(Basket, {
                    label = data.current["realLabel"],
                    value = data.current["item"],
                    amount = data.current.value,
                    price = data.current["price"]
                })
            end
            payAmount = payAmount + data.current["price"] * data.current.value
            TriggerEvent('notification', 'Sepetine ' .. data.current.value .. ' adet ' .. data.current["realLabel"] .. ' koydun.', 1) -- Put " .. data.current.value .. " pieces of " .. data.current["realLabel"] .. " in the basket       
        end,
    function(data, menu)
        menu.close()
    end)
end

--[[ Check if item already in basket ]]--
CheckBasketItem = function(item)
    for i=1, #Basket do
        if item == Basket[i]["value"] then
            return true, Basket[i]
        end
    end
    return false, nil
end

--[[ Checks if key "L" is pressed ]]--
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3)
        if IsControlJustPressed(0, Keys["L"]) then
            OpenBasket()
        end
    end
end)

-- [[ Opens basket menu ]]--
OpenBasket = function()
    if payAmount > 0 and #Basket then
        local elements = {
            {label = 'Tutar: <span style="color:green">$' .. payAmount},
        }
        for i=1, #Basket do
            local item = Basket[i]
            table.insert(elements, {
                label = '<span style="color:red">*</span> ' .. item["label"] .. ': ' .. item["amount"] .. ' adet (<span style="color:green">$' .. item["price"] * item["amount"] .. '</span>)',
                value = "item_menu",
                index = i
            })
        end
        table.insert(elements, {label = '<span style="color:red">Sepeti Boşalt', value = "empty"})

        ESX.UI.Menu.CloseAll()
        ESX.UI.Menu.Open(
            'default', GetCurrentResourceName(), 'basket',
            {
                title    = "Sepet",
                align    = 'center',
                elements = elements
            },
            function(data, menu)
                if data.current.value == 'empty' then
                    Basket = {}
                    payAmount = 0
                    menu.close()
                    TriggerEvent('notification', 'Sepetinden her seyi kaldirdin.', 1)
                end
                if data.current.value == "item_menu" then
                    menu.close()
                    local index = data.current.index
                    local shopItem = Basket[index]

                    ESX.UI.Menu.Open(
                        'default', GetCurrentResourceName(), 'basket_detailedmenu',
                        {
                            title    = "Sepet - " .. shopItem["label"] .. " - " .. shopItem["amount"] .. "adet",
                            align    = 'center',
                            elements = {
                                {label = shopItem["label"] .. " - $" .. shopItem["price"] * shopItem["amount"]},
                                {label = '<span style="color:red">Eşyayı Sil</span>', value = "deleteItem"},
                            },
                        },
                        function(data2, menu2)
                            if data2.current["value"] == "deleteItem" then
                                TriggerEvent('notification', 'Sepetinden ' .. Basket[index]["amount"] ..' adet '.. Basket[index]["label"] .. ' kaldirdin.', 1) -- Removed " .. Basket[index]["amount"] .." ".. Basket[index]["label"] .. " from basket.
                                payAmount = payAmount - (Basket[index]["amount"] * Basket[index]["price"])
                                table.remove(Basket, index)
                                OpenBasket()
                            end
                        end,
                        function(data2, menu2)
                            menu2.close()
                            OpenBasket()
                        end
                    )
                    
                    -- [[ Back to normal basket menu ]] --
                end
            end,
            function(data, menu)
                menu.close()
            end
        )
    else
        ESX.UI.Menu.CloseAll()
    end
end
