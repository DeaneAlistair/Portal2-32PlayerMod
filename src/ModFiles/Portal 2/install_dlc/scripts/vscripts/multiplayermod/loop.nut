//---------------------------------------------------
//         *****!Do not edit this file!*****
//---------------------------------------------------
//   _                     _
//  | |    ___  ___  _ __ (_)
//  | |__ / _ \/ _ \| '_ \ _
//  |____|\___/\___/| .__/(_)
//                  |_|
//---------------------------------------------------
// Purpose: Set up a giant function to loop every
// 0.1 second (by default) in case of changes and
//          events that occur midgame.
//---------------------------------------------------

LastCoordGetPlayer <- null
CoordsAlternate <- false
PreviousTime01Sec <- 0
setspot <- Vector(0, 0, 250) //Vector(5107, 3566, -250)

function loop() {
    //## Event List ##//
    if (EventList.len() > 0) {
        SendToConsoleP232("script " + EventList[0])
        EventList.remove(0)
    }

    //## Hook player join ##//
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        if (p.ValidateScriptScope()) {
            local script_scope = p.GetScriptScope()
            // If player hasn't joined yet / hasn't been spawned / colored yet
            if (!("Colored" in script_scope)) {
                // Run player join code
                OnPlayerJoin(p, script_scope)
            }
        }
    }

    //## PotatoIfy loop ##//
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        local currentplayerclass = FindPlayerClass(p)
        if (currentplayerclass.potatogun) {
            PotatoIfy(p)
        }
        if (!currentplayerclass.potatogun) {
            UnPotatoIfy(p)
        }
    }
    // Also update everyones class if PermaPotato is on
    if (PermaPotato) {
        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            local currentplayerclass = FindPlayerClass(p)
            currentplayerclass.potatogun <- true
        }
    }
    if (!PermaPotato) {
        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            local currentplayerclass = FindPlayerClass(p)
            currentplayerclass.potatogun <- false
        }
    }

    //## Update eye angles ##//
    if (Config_UseNametags) {
        if (!CoordsAlternate) {
            // Alternate so our timings space out correctly
            if (LastCoordGetPlayer != null) {
                LastCoordGetPlayer <- Entities.FindByClassname(LastCoordGetPlayer, "player")
            } else {
                LastCoordGetPlayer <- Entities.FindByClassname(null, "player")
            }
            if (LastCoordGetPlayer != null) {
                EntFireByHandle(measuremovement, "SetMeasureTarget", LastCoordGetPlayer.GetName(), 0.0, null, null)
                // Alternate so our timings space out correctly
                CoordsAlternate <- true
            }
        } else {
            if (LastCoordGetPlayer != null && Entities.FindByName(null, "p2mm_logic_measure_movement")) {
                local currentplayerclass = FindPlayerClass(LastCoordGetPlayer)
                if (currentplayerclass != null) {
                    if (OriginalAngle == null && CanCheckAngle) {
                        OriginalAngle <- measuremovement.GetAngles()
                        Entities.FindByClassname(null, "player").SetAngles(OriginalAngle.x + 7.0, OriginalAngle.y + 4.7, OriginalAngle.z + 7.1)
                    }

                    currentplayerclass.eyeangles <- measuremovement.GetAngles()
                    currentplayerclass.eyeforwardvector <- measuremovement.GetForwardVector()
                }
            }
            // Alternate so our timings space out correctly
            CoordsAlternate <- false
        }
    } else {
        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            FindPlayerClass(p).eyeangles <- Vector(0, 0, 0)
            FindPlayerClass(p).eyeforwardvector <- Vector(0, 0, 0)
        }
    }

    //## Update Portal Gun names ##//
    local ent = null
    while (ent = Entities.FindByClassname(ent, "weapon_portalgun")) {
        // if it doesnt have a name yet
        if (ent.GetName() == "") {
            // Set The Name Of The Portalgun
            ent.__KeyValueFromString("targetname", "weapon_portalgun_player" + ent.GetRootMoveParent().entindex())
        }
    }

    // //## Nametags ##//
    if (Config_UseNametags) {
        if (Time() - PreviousNametagItter > 0.1) {
            PreviousNametagItter = Time()
            local p = null
            while (p = Entities.FindByClassname(p, "player")) {
                local currentplayerclass = FindPlayerClass(p)
                if (currentplayerclass != null) {

                    // Get number of players in the game
                    local playernums = 0
                    foreach (plr in playerclasses) {
                        playernums = playernums + 1
                    }

                    local checkcount = 1
                    // Optimise search based on player count
                    if (playernums <= 6) {
                        checkcount = playernums
                    } else {
                        if (playernums <= 11) {
                            checkcount = 6
                        } else {
                            if (playernums <= 14) {
                                checkcount = 4
                            } else {
                                if (playernums <= 17) {
                                    checkcount = 3
                                } else {
                                    if (playernums <= 21) {
                                        checkcount = 2
                                    } else {
                                        if (playernums <= 33) {
                                            checkcount = 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                    local eyeplayer = ForwardVectorTraceLine(p.EyePosition(), currentplayerclass.eyeforwardvector, 0, 10000, checkcount, 1, 32, p, "player")
                    if (eyeplayer != null) {
                        local clr = GetPlayerColor(eyeplayer, true)
                        local cpc = FindPlayerClass(eyeplayer)
                        EntFireByHandle(nametagdisplay, "settextcolor", clr.r + " " + clr.g + " " + clr.b, 0, p, p)
                        EntFireByHandle(nametagdisplay, "settext", cpc.username, 0, p, p)
                        EntFireByHandle(nametagdisplay, "display", "", 0, p, p)
                    }
                }
            }   
        }
    }


    //## Set PlayerModel ##//
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        local currentplayerclass = FindPlayerClass(p)
        if (currentplayerclass != null) {
            if (currentplayerclass.playermodel != null) {
                if (currentplayerclass.playermodel != p.GetModelName()) {
                    EntFire("p2mm_servercommand", "command", "script Entities.FindByName(null, \"" + p.GetName() + "\").SetModel(\"" + currentplayerclass.playermodel + "\")", 1)
                }
            }
        }
    }


    // // ENTITY OPTIMIZATION / DELETION ///////////////
    // local cnt = GetEntityCount()
    // local amtpast = cnt - (EntityCap - EntityCapLeeway) // this is the amount of entities we have past the caps leeway amount
    // local amtdeleted = 0

    // if (cnt > EntityCap - EntityCapLeeway) {
    //     if (cnt >= FailsafeEntityCap) {
    //         printl("CRASH AND BURN!!!!: ENTITY COUNT HAS EXCEEDED THE ABSOLUTE MAXIMUM OF " + FailsafeEntityCap + "!  EXITING TO HUB TO PREVENT CRASH!")
    //         SendToConsoleP232("changelevel mp_coop_lobby_3")
    //     }
    //     printl("LEEWAY EXCEEDED (AMOUNT: " + amtpast + ") CAP: " + EntityCap + " LEEWAY: " + EntityCapLeeway + " ENTITY COUNT: " + cnt + "AMT DELETED: " + amtdeleted)
    //     foreach (entclass in ExpendableEntities) {

    //         local curdelamt = amtpast - amtdeleted
    //         if (amtdeleted < amtpast) { // if we are still over the cap

    //             local amt = GetEntityCount(entclass)
    //             printl("CURRENT AMOUNT OF " + entclass + ": " + amt)

    //             if (amt > 0) {
    //                 if (amt >= curdelamt) {
    //                     DeleteAmountOfEntities(entclass, curdelamt)
    //                     return
    //                 } else {
    //                     DeleteAmountOfEntities(entclass, amt)
    //                     amtdeleted = amtdeleted + amt
    //                 }
    //             }


    //         } else {
    //             return
    //         }
    //     }
    // }

    /////////////////////////////////////////////////


    //## Cache original spawn position ##//
    if (cacheoriginalplayerposition == 0 && Entities.FindByClassname(null, "player")) {
        // OldPlayerPos = the blues inital spawn position
        try {
            OldPlayerPos <- Entities.FindByName(null, "blue").GetOrigin()
            OldPlayerAngles <- Entities.FindByName(null, "blue").GetAngles()
        } catch (exception) {
            try {
                OldPlayerPos <- Entities.FindByName(null, "info_coop_spawn").GetOrigin()
                OldPlayerAngles <- Entities.FindByName(null, "info_coop_spawn").GetAngles()
            } catch (exception) {
                    try {
                        OldPlayerPos <- Entities.FindByName(null, "info_player_start").GetOrigin()
                        OldPlayerAngles <- Entities.FindByName(null, "info_player_start").GetAngles()
                    } catch(exception) {
                        OldPlayerPos <- Vector(0, 0, 0)
                        OldPlayerAngles <- Vector(0, 0, 0)
                        if (GetDeveloperLevel()) {
                            printl("(P2:MM): Error: Could not cache player position. This is catastrophic!")
                        }
                        cacheoriginalplayerposition <- 1
                    }
                }
            }
        cacheoriginalplayerposition <- 1
    }

    //## Detect death ##//
    local progress = true
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        // If player is dead
        if (p.GetHealth() == 0) {
            // Put dead players in the dead players array
            foreach (player in CurrentlyDead) {
                if (player == p) {
                    progress = false
                }
            }
            if (progress) {
                CurrentlyDead.push(p)
                OnPlayerDeath(p)
            }
        }
    }

    //## Hook first spawn ##//
    if (PostMapLoadDone) {
        if (!DoneWaiting) {
            if (CanHook) {
                if (Entities.FindByClassname(null, "player").GetHealth() < 200003001 || Entities.FindByClassname(null, "player").GetHealth() > 230053963) {
                    DoneWaiting <- true
                    GeneralOneTime()
                    if (GetDeveloperLevel()) {
                        printl("=================================HEALTH SPAWN")
                    }
                }
            }
            DoEntFire("p2mm_wait_for_players_text", "display", "", 0.0, null, null)
        }
    }

    //## GlobalSpawnClass SetSpawn ##//
    if (GlobalSpawnClass.usesetspawn) {
        local p = null
        while (p = Entities.FindByClassnameWithin(p, "player", GlobalSpawnClass.setspawn.position, GlobalSpawnClass.setspawn.radius)) {
            TeleportToSpawnPoint(p, null)
        }
    }

    //## MapSupport loop ##//
    MapSupport(false, true, false, false, false, false, false)


    //## Run all custom generated props / prop related Garry's Mod code ##//
    CreatePropsForLevel(false, false, true)


    //## Config developer mode loop ##//
    if (DevModeConfig) {
        // Change Config_DevMode variable based on convar "developer"
        if (!GetDeveloperLevel()) {
            if (StartDevModeCheck) {
                Config_DevMode <- false
            }
        } else {
            Config_DevMode <- true
        }
    }

    ////#### FUN STUFF ####////

    //## Rocket ##//
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        local currentplayerclass = FindPlayerClass(p)
        if (currentplayerclass.rocket) {
            if (p.GetVelocity().z <= 1) {
                EntFireByHandle(p, "sethealth", "-91", 0, p, p)
                currentplayerclass.rocket <- false
            }
        }
    }

    // Random turret models & colors
    if (Config_RandomTurrets && HasSpawned) {
        local ent = null
        while (ent = Entities.FindByClassname(ent, "npc_portal_turret_floor")) {
            local script_scope = ent.GetScriptScope()
            if (ent.GetTeam() != 69420) {
                local modelnumber = RandomInt(0, 2)
                if (modelnumber == 2) {
                    modelnumber = 4
                }
                ent.__KeyValueFromInt("ModelIndex", modelnumber)
                local RTurretColor = RandomColor()

                b <- RTurretColor.b
                g <- RTurretColor.g
                r <- RTurretColor.r

                local model = RandomInt(0, 2)

                if (model == 1) {
                    ent.SetModel("models/npcs/turret/turret_skeleton.mdl")
                }
                if (model == 2) {
                    ent.SetModel("models/npcs/turret/turret_backwards.mdl")
                }

                EntFireByHandle(ent, "Color", (R + " " + G + " " + R), 0, null, null)
                ent.SetTeam(69420)
            }
        }
    }

    //////////////////////////
    // RUNS EVERY 5 SECONDS //
    //////////////////////////

    if (Time() >= PreviousTime5Sec + 5) {
        PreviousTime5Sec = Time()
        
        // Color display
        if (Config_UseColorIndicator) {
            local p = null
            while (p = Entities.FindByClassname(p, "player")) {
                DisplayPlayerColor(p)
            }
        }
    }

    ///////////////////////
    // RUNS EVERY SECOND //
    ///////////////////////

    if (Time() >= PreviousTime1Sec + 1) {
        PreviousTime1Sec <- Time()

        // Random portal sizes
        if (Config_RandomPortalSize) {
            randomportalsize <- RandomInt(1, 100 ).tostring()
            randomportalsizeh <- RandomInt(1, 100 ).tostring()

            try {
                local ent = null
                while (ent = Entities.FindByClassname(ent, "prop_portal")) {
                    ent.__KeyValueFromString("HalfWidth", randomportalsize)
                    ent.__KeyValueFromString("HalfHeight", randomportalsizeh)
                }
            } catch (exception) {}
        }

        //## Detect respawn ##//
        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            if (p.GetHealth() >= 1) {
                // Get the players from the dead players array
                foreach (index, player in CurrentlyDead) {
                    if (player == p) {
                        CurrentlyDead.remove(index)
                        OnPlayerRespawn(p)
                    }
                }
            }
        }

        //## Singleplayer check that must be looped in case sv_cheats was changed ##//
        if (GlobalOverridePluginGrabController) {
            if (PluginLoaded) {
                if (IsOnSingleplayerMaps) {
                    SetPhysTypeConvar(0) // enable real-time physics
                } else {
                    SetPhysTypeConvar(-1) // enable viewmodel physics, in case of changes. MP Gamerules already defaults to this without plugin
                }
            }
        }
    }
}