local S
if minetest.get_modpath("intllib") then
    S = intllib.Getter()
else
    S = function(s,a,...)a={a,...}return s:gsub("@(%d+)",function(n)return a[tonumber(n)]end)end
end

--configuration stuff

local light_tool_enable = minetest.settings:get_bool("hst_enable_light_tool", true)
local lights = minetest.settings:get_bool("hst_enable_lights", true)
local light_separation = tonumber(minetest.settings:get("hst_light_beam_separation") or 4)
local light_dist = tonumber(minetest.settings:get("hst_light_beam_distance") or 20)
if minetest.get_modpath("light_tool") then
	local light_tool = true
end
local vect = {}

--TODO add day/night light settings as the driver's side should be illuminated during the night and the other side during the day.
--Fix the issue of the lights dissapearing when out of render distance but within active object area. 		- FIXED, but could still be improved
--Maybe add interior lighting for the coaches
--Sound effects
--IMPORTANT door animations
--tidy up code

minetest.register_entity("hst:lights_front",{
	visual_size = {x=1, y=1},
	visual = "mesh",
	mesh = "hst_lights_powercar.obj",
	textures = {"hst_lights_front.png"},
	use_texture_alpha = true,		
	glow = 15,
	on_step = function(self, dtime)			--Remove if it gets detached from the wagon
		if not self.object:get_attach() then
			self.object:remove()
		end
	end,
})

minetest.register_entity("hst:lights_rear",{
	visual_size = {x=1, y=1},
	visual = "mesh",
	mesh = "hst_lights_powercar.obj",
	textures = {"hst_lights_rear.png"},
	use_texture_alpha = true,	
	glow = 15,
	on_step = function(self, dtime)
		if not self.object:get_attach() then
			self.object:remove()
		end
	end,
})

advtrains.register_wagon("hst_powercar", {
	mesh="hst_powercar.obj",
	textures={"hst_powercar.png"},
	drives_on={default=true},
	max_speed=20,
	seats = {
		{
			name=S("Driver stand"),
			attach_offset={x=0, y=-2.5, z=20},
			view_offset={x=0, y=-2.5, z=18},
			driving_ctrl_access=true,
			group="dstand",
		},
	},
	seat_groups = {
		dstand={
			name = "Driver Stand",
			access_to = {},
			require_doors_open=false,
			driving_ctrl_access=true,
		},
	},
	assign_to_seat_group = {"dstand"},
	custom_on_activate = function(self, staticdata_table, dtime_s)		--initial spawner
		if not lights then
			return
		end
		self.lights = minetest.add_entity(self.object:getpos(), "hst:lights_front")
		self.lights:set_armor_groups({immortal=1})
		self.lights:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
		self.flights = true		--"flights" - Front Lights
	end,
	custom_on_step = function(self, dtime)
		if not lights then
			return
		end
		self.data = advtrains.wagons[self.id]
		if self.data.wagon_flipped and self.flights then		--If the wagon is reversing and there are no rear lights already
			self.lights:set_detach()
			self.lights = minetest.add_entity(self.object:getpos(), "hst:lights_rear")
			self.lights:set_armor_groups({immortal=1})
			self.lights:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			self.flights = false
		elseif not self.data.wagon_flipped and not self.flights then
			self.lights:set_detach()
			self.lights = minetest.add_entity(self.object:getpos(), "hst:lights_front")
			self.lights:set_armor_groups({immortal=1})
			self.lights:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
			self.flights = true
		elseif not self.lights:get_attach() then
			self.flights = not self.flights		--Attach lights if there is nothing attached to the wagon
		end
		if light_tool and self.flights and light_tool_enable then		--enable light_tool
			local pos = self.object:get_pos()
			local yaw = (math.pi/2) + self.object:get_yaw()			--rotate by 90 degrees
			vect.x = math.cos(yaw)						--convert yaw in radians to a unit vector
			vect.z = math.sin(yaw)
			light_tool.light_beam({x=pos.x+(vect.x*light_separation), y=pos.y+1, z=pos.z+(vect.z*light_separation)}, {x=vect.x, y=0, z=vect.z}, light_dist)
		end			
	end,
	door_entry={-1},
	assign_to_seat_group = {"dstand"},
	visual_size = {x=1, y=1},
	wagon_span=3,
	is_locomotive=true,
	collisionbox = {-1.0,-0.4,-1.0, 1.0,2.0,1.0},
	drops={"default:steelblock 3"},
}, S("Class 43 Power car\n(Intercity 125 swallow livery)"), "hst_powercar_inv.png")

advtrains.register_wagon("hst_carriage", {
	mesh="hst_carriage.obj",
	textures = {"hst_carriage.png"},
	drives_on={default=true},
	max_speed=20,
	seats = {
		{
			name="1",
			attach_offset={x=-3.3, y=-2.6, z=-10},
			view_offset={x=-5.5, y=-2.5, z=3},
			group="pass",
		},
		{
			name="2",
			attach_offset={x=4, y=8, z=8},
			view_offset={x=0, y=0, z=0},
			group="pass",
		},
		{
			name="1a",
			attach_offset={x=-4, y=8, z=0},
			view_offset={x=0, y=0, z=0},
			group="pass",
		},
		{
			name="2a",
			attach_offset={x=4, y=8, z=0},
			view_offset={x=0, y=0, z=0},
			group="pass",
		},
		{
			name="3",
			attach_offset={x=-4, y=8, z=-8},
			view_offset={x=0, y=0, z=0},
			group="pass",
		},
		{
			name="4",
			attach_offset={x=4, y=8, z=-8},
			view_offset={x=0, y=0, z=0},
			group="pass",
		},
	},
	seat_groups = {
		pass={
			name = "Passenger area",
			access_to = {},
			require_doors_open=true,
		},
	},
	assign_to_seat_group = {"pass"},
	doors={
		open={
			[-1]={frames={x=0, y=40}, time=1},
			[1]={frames={x=80, y=120}, time=1}
		},
		close={
			[-1]={frames={x=40, y=80}, time=1},
			[1]={frames={x=120, y=160}, time=1}
		}
	},
	door_entry={-1, 1},
	visual_size = {x=1, y=1},
	wagon_span=3.13,
	collisionbox = {-1.0,-0.4,-1.0, 1.0,2.0,1.0},
	drops={"default:steelblock 3"},
}, S("Mk3 Coach\n(Intercity 125 swallow livery)"), "hst_carriage_inv.png")

minetest.register_craft({
	output = 'advtrains:hst_powercar',
	recipe = {
		{'dye:blue', 'dye:blue', 'dye:yellow'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'advtrains:wheel', 'dye:white', 'advtrains:wheel'},
	},
})

minetest.register_craft({
	output = 'advtrains:hst_carriage',
	recipe = {
		{'dye:blue', 'default:glass', 'dye:blue'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'advtrains:wheel', 'dye:white', 'advtrains:wheel'},
	},
})
