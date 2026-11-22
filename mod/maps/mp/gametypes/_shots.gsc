// Screenshot views: save the host's exact view, and put it back later or in another build.
//
//   /set shot save NAME   saves the current view as NAME
//   /set shot NAME        restores the view saved as NAME
//
// Views live in scriptdata/shots.cfg, one per line:
//   name,map,state,x,y,z,pitch,yaw,roll
// It's a CSV file named .cfg: with sv_pure 1, the game only reads loose .cfg and .menu files.
// Saving appends a line; restoring uses the last line with that name, so saving a name again
// replaces its view. Spectator views are restored by spawning as a spectator there (no gravity,
// no gun); others with setOrigin.

init()
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
		p = players[0];
		args = words(cmd);
		if(!args.size)
			continue;
		if(args[0] == "save")
		{
			name = "unnamed";
			if(args.size > 1)
				name = args[1];
			p saveView(name);
		}
		else
			p restoreView(args[0]);
	}
}

saveView(name)
{
	o = self.origin;
	a = self getPlayerAngles();
	line = name + "," + getCvar("mapname") + "," + self.sessionstate + "," + o[0] + "," + o[1] + "," + o[2] + "," + a[0] + "," + a[1] + "," + a[2];

	// A new file starts with a header row
	f = openfile("shots.cfg", "read");
	if(f == -1)
	{
		f = openfile("shots.cfg", "write");
		if(f != -1)
			fprintln(f, "name,map,state,x,y,z,pitch,yaw,roll");
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
	// Reading only looks at the first 9 fields, so the trailing comma doesn't matter.
	fprintln(f, "\n" + line);
	closefile(f);
	logPrint("shot: saved " + line + "\n");
	self iprintln("shot: saved " + name);
}

restoreView(name)
{
	f = openfile("shots.cfg", "read");
	if(f == -1)
	{
		self iprintln("shot: no scriptdata/shots.cfg yet; save a view first");
		return;
	}
	view = undefined;
	for(;;)
	{
		count = freadln(f);
		if(count == -1)
			break;
		if(count < 9 || fgetarg(f, 0) != name)
			continue;
		view = [];
		for(i = 0; i < 9; i++)
			view[i] = fgetarg(f, i);
	}
	closefile(f);

	if(!isDefined(view))
	{
		self iprintln("shot: no view named " + name);
		return;
	}
	if(view[1] != getCvar("mapname"))
	{
		self iprintln("shot: " + name + " is on " + view[1]);
		return;
	}
	origin = (number(view[3]), number(view[4]), number(view[5]));
	angles = (number(view[6]), number(view[7]), number(view[8]));
	if(view[2] == "spectator")
		self spectateAt(origin, angles);
	else
	{
		self setOrigin(origin);
		self setPlayerAngles(angles);
	}
	self iprintln("shot: " + name);
}

spectateAt(origin, angles)
{
	// What each stock gametype's own spawnSpectator does. Every gametype defines its own copy,
	// so this script can't call theirs.
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

words(s)
{
	// The built-in strtok returns garbled words in a listen server, so split by hand
	out = [];
	word = "";
	for(i = 0; i < s.size; i++)
	{
		if(s[i] == " ")
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
