// Screenshot views: save a player's exact view and state, and put them back later or in another build.
//
// Any player, from the console or a bind:
//   /openScriptMenu shot save:NAME   saves your view as NAME
//   /openScriptMenu shot NAME        restores it
// The host can also use:
//   /set shot save NAME
//   /set shot NAME
//
// A view holds where you are and where you look, and whether you're a spectator or playing. If
// playing, it also holds your team, class, held weapon, stance and whether you aim down the sights.
// Restoring changes only what differs, so the same shot can be restaged quickly. Several players
// can each restore their own view to stage a shot together.
//
// Views live in scriptdata/shots.cfg, one per line:
//   name,map,state,team,class,weapon,stance,ads,x,y,z,pitch,yaw,roll
// Older lines with just name,map,state,x,y,z,pitch,yaw,roll still restore.
// It's a CSV file named .cfg: with sv_pure 1, the game only reads loose .cfg and .menu files.
// Saving appends a line; restoring uses the last line with that name.

init()
{
	// Menus run client commands for us: stance and aiming down the sights have no script functions.
	precacheMenu("shot");
	precacheMenu("shot_lower");
	precacheMenu("shot_raise");
	precacheMenu("shot_ads");

	level thread onPlayerConnect();
	level thread hostCommands();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);
		player thread onMenuResponse();
	}
}

onMenuResponse()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		if(menu != "shot")
			continue;
		args = split(response, ":");
		if(args.size > 1 && args[0] == "save")
			self thread command("save", args[1]);
		else if(args.size)
			self thread command(args[0], undefined);
	}
}

hostCommands()
{
	setCvar("shot", "");
	for(;;)
	{
		wait 0.05;
		cmd = getCvar("shot");
		if(cmd == "")
			continue;
		setCvar("shot", "");

		players = getentarray("player", "classname");
		if(!players.size)
			continue;
		args = split(cmd, " ");
		if(args.size > 1 && args[0] == "save")
			players[0] thread command("save", args[1]);
		else if(args.size)
			players[0] thread command(args[0], undefined);
	}
}

command(verb, name)
{
	if(isDefined(self.shotBusy))
	{
		self iprintln("shot: still restoring");
		return;
	}
	self.shotBusy = true;
	if(verb == "save")
		self saveView(name);
	else
		self restoreView(verb);
	self.shotBusy = undefined;
}

saveView(name)
{
	o = self.origin;
	a = self getPlayerAngles();
	team = "spectator";
	if(isDefined(self.pers["team"]))
		team = self.pers["team"];
	class = "none";
	if(isDefined(self.pers["weapon"]))
		class = self.pers["weapon"];
	weapon = "none";
	stance = "stand";
	ads = 0;
	if(self.sessionstate == "playing")
	{
		weapon = self getCurrentWeapon();
		stance = self currentStance();
		if(self playerADS() > 0.5)
			ads = 1;
	}
	line = name + "," + getCvar("mapname") + "," + self.sessionstate + "," + team + "," + class + "," + weapon + "," + stance + "," + ads
		+ "," + o[0] + "," + o[1] + "," + o[2] + "," + a[0] + "," + a[1] + "," + a[2];

	// A new file starts with a header row
	f = openfile("shots.cfg", "read");
	if(f == -1)
	{
		f = openfile("shots.cfg", "write");
		if(f != -1)
			fprintln(f, "name,map,state,team,class,weapon,stance,ads,x,y,z,pitch,yaw,roll");
	}
	else
	{
		closefile(f);
		f = openfile("shots.cfg", "append");
	}
	if(f == -1)
	{
		self iprintln("shot: can't write scriptdata/shots.cfg");
		return;
	}
	// fprintln writes its text and a comma, but no line break, so each record starts with one.
	// Reading only looks at the fields it knows, so the trailing comma doesn't matter.
	fprintln(f, "\n" + line);
	closefile(f);
	logPrint("shot: saved " + line + "\n");
	self iprintln("shot: saved " + name);
}

readView(name)
{
	f = openfile("shots.cfg", "read");
	if(f == -1)
		return undefined;
	view = undefined;
	for(;;)
	{
		count = freadln(f);
		if(count == -1)
			break;
		if(count < 9 || fgetarg(f, 0) != name)
			continue;
		view = [];
		view["map"] = fgetarg(f, 1);
		view["state"] = fgetarg(f, 2);
		if(count >= 14)
		{
			view["team"] = fgetarg(f, 3);
			view["class"] = fgetarg(f, 4);
			view["weapon"] = fgetarg(f, 5);
			view["stance"] = fgetarg(f, 6);
			view["ads"] = fgetarg(f, 7) == "1";
			first = 8;
		}
		else
			first = 3;
		view["origin"] = (number(fgetarg(f, first)), number(fgetarg(f, first + 1)), number(fgetarg(f, first + 2)));
		view["angles"] = (number(fgetarg(f, first + 3)), number(fgetarg(f, first + 4)), number(fgetarg(f, first + 5)));
	}
	closefile(f);
	return view;
}

restoreView(name)
{
	view = readView(name);
	if(!isDefined(view))
	{
		self iprintln("shot: no view named " + name + " in scriptdata/shots.cfg");
		return;
	}
	if(view["map"] != getCvar("mapname"))
	{
		self iprintln("shot: " + name + " is on " + view["map"]);
		return;
	}
	self closeMenu();
	self closeInGameMenu();

	if(view["state"] != "playing")
	{
		self spectateAt(view["origin"], view["angles"]);
		self iprintln("shot: " + name);
		return;
	}
	if(!isDefined(view["team"]))
	{
		// An older line: just move there
		self setOrigin(view["origin"]);
		self setPlayerAngles(view["angles"]);
		self iprintln("shot: " + name);
		return;
	}

	if(!self joinAs(view["team"], view["class"]))
	{
		self iprintln("shot: couldn't spawn as " + view["team"] + " with " + view["class"]);
		return;
	}
	self setOrigin(view["origin"]);
	self setPlayerAngles(view["angles"]);

	if(view["weapon"] != "none" && self getCurrentWeapon() != view["weapon"] && self hasWeapon(view["weapon"]))
	{
		self switchToWeapon(view["weapon"]);
		for(i = 0; i < 40 && self getCurrentWeapon() != view["weapon"]; i++)
			wait 0.05;
	}
	self changeStance(view["stance"]);
	self changeADS(view["ads"]);
	self setPlayerAngles(view["angles"]);
	// The helper menus close themselves, but the HUD stays hidden until the next input unless the
	// server closes menus too.
	wait 0.05;
	self closeMenu();
	self closeInGameMenu();
	logPrint("shot: restored " + name + " for " + self.name + ": stance " + self currentStance() + ", ads " + self playerADS() + "\n");
	self iprintln("shot: " + name);
}

joinAs(team, class)
{
	// The gametype's own menu handling switches team and class, the same as clicking through the menus.
	if(self.sessionstate == "playing" && self.pers["team"] == team && isDefined(self.pers["weapon"]) && self.pers["weapon"] == class)
		return true;
	if(isDefined(self.pers["team"]) && self.pers["team"] != "spectator")
	{
		self notify("menuresponse", game["menu_team"], "spectator");
		wait 0.1;
	}
	self notify("menuresponse", game["menu_team"], team);
	wait 0.1;
	self notify("menuresponse", game["menu_weapon_" + team], class);
	for(i = 0; i < 60 && self.sessionstate != "playing"; i++)
		wait 0.05;
	logPrint("shot: " + self.name + " joined " + self.pers["team"] + " as " + self.sessionstate + "\n");
	return self.sessionstate == "playing";
}

currentStance()
{
	// No script function reads stance (getEye is a fixed 40), but a trace straight down onto the
	// player stops at the top of their box: 70 standing, 50 crouched, 30 prone.
	trace = bulletTrace(self.origin + (0, 0, 80), self.origin, true, undefined);
	if(!isDefined(trace["entity"]) || trace["entity"] != self)
		return "stand";  // something overhead got in the way
	height = trace["position"][2] - self.origin[2];
	if(height > 60)
		return "stand";
	if(height > 40)
		return "crouch";
	return "prone";
}

changeStance(target)
{
	order = [];
	order["stand"] = 0;
	order["crouch"] = 1;
	order["prone"] = 2;
	if(!isDefined(order[target]))
		return;
	for(i = 0; i < 6; i++)
	{
		current = self currentStance();
		if(current == target)
			return;
		if(order[current] < order[target])
			self openMenuNoMouse("shot_lower");
		else
			self openMenuNoMouse("shot_raise");
		wait 0.6;
	}
	logPrint("shot: " + self.name + " is " + self currentStance() + ", not " + target + "\n");
}

changeADS(want)
{
	for(i = 0; i < 3; i++)
	{
		if((self playerADS() > 0.5) == want)
			return;
		self openMenuNoMouse("shot_ads");
		wait 0.5;
	}
	logPrint("shot: " + self.name + " ads is " + self playerADS() + ", not " + want + "\n");
}

spectateAt(origin, angles)
{
	// Switch to spectator through the gametype, then spawn where the view was. Every gametype defines
	// its own spawnSpectator, so this script can't call theirs; this does what they do.
	if(self.sessionstate != "spectator")
	{
		self notify("menuresponse", game["menu_team"], "spectator");
		wait 0.1;
	}
	self notify("spawned");
	self notify("end_respawn");
	resettimeout();
	self stopShellshock();
	self stoprumble("damage_heavy");
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self spawn(origin, angles);
}

split(s, separator)
{
	// The built-in strtok returns garbled words in a listen server, so split by hand
	out = [];
	word = "";
	for(i = 0; i < s.size; i++)
	{
		if(s[i] == separator)
		{
			if(word != "")
				out[out.size] = word;
			word = "";
		}
		else
			word += s[i];
	}
	if(word != "")
		out[out.size] = word;
	return out;
}

number(s)
{
	// Scripts can't parse numbers, but cvars can
	setCvar("shot_tmp", s);
	return getCvarFloat("shot_tmp");
}
