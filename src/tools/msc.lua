---
-- msc.lua
-- Interface for the MS C/C++ compiler.
-- Author Jason Perkins
-- Modified by Manu Evans
-- Copyright (c) 2009-2015 Jason Perkins and the Premake project
---


	premake.tools.msc = {}
	local msc = premake.tools.msc
	local project = premake.project
	local config = premake.config


--
-- Returns list of C preprocessor flags for a configuration.
--

	function msc.getcppflags(cfg)
		return {}
	end


--
-- Returns list of C compiler flags for a configuration.
--

	msc.cflags = {
		clr = {
			On = "/clr",
			Unsafe = "/clr",
			Pure = "/clr:pure",
			Safe = "/clr:safe",
		},
		flags = {
			FatalCompileWarnings = "/WX",
			MultiProcessorCompile = "/MP",
			NoFramePointer = "/Oy",
			NoMinimalRebuild = "/Gm-",
			SEH = "/EHa",
			Symbols = "/Z7",
			OmitDefaultLibrary = "/Zl",
		},
		floatingpoint = {
			Fast = "/fp:fast",
			Strict = "/fp:strict",
		},
		callingconvention = {
			Cdecl = "/Gd",
			FastCall = "/Gr",
			StdCall = "/Gz",
			VectorCall = "/Gv",
		},
		optimize = {
			Off = "/Od",
			On = "/Ot",
			Debug = "/Od",
			Full = "/Ox",
			Size = "/O1",
			Speed = "/O2",
		},
		vectorextensions = {
			AVX = "/arch:AVX",
			AVX2 = "/arch:AVX2",
			SSE = "/arch:SSE",
			SSE2 = "/arch:SSE2",
		},
		warnings = {
			Extra = "/W4",
			Off = "/W0",
		}
	}

	function msc.getcflags(cfg)
		local flags = config.mapFlags(cfg, msc.cflags)

		flags = table.join(flags, msc.getwarnings(cfg))

		local runtime = iif(cfg.flags.StaticRuntime, "/MT", "/MD")
		if config.isDebugBuild(cfg) then
			runtime = runtime .. "d"
		end
		table.insert(flags, runtime)

		return flags
	end

	function msc.getwarnings(cfg)
		local result = {}
		-- NOTE: VStudio can't enable specific warnings (workaround?)
		for _, disable in ipairs(cfg.disablewarnings) do
			table.insert(result, '/wd"' .. disable .. '"')
		end
		for _, fatal in ipairs(cfg.fatalwarnings) do
			table.insert(result, '/we"' .. fatal .. '"')
		end
		return result
	end


--
-- Returns list of C++ compiler flags for a configuration.
--

	msc.cxxflags = {
		flags = {
			NoRTTI = "/GR-",
		}
	}

	function msc.getcxxflags(cfg)
		local flags = config.mapFlags(cfg, msc.cxxflags)

		if not cfg.flags.SEH and not cfg.flags.NoExceptions then
			table.insert(flags, "/EHsc")
		end

		return flags
	end


--
-- Decorate defines for the MSVC command line.
--

	function msc.getdefines(defines)
		local result = {}
		for _, define in ipairs(defines) do
			table.insert(result, '/D"' .. define .. '"')
		end
		return result
	end

	function msc.getundefines(undefines)
		local result = {}
		for _, undefine in ipairs(undefines) do
			table.insert(result, '/U"' .. undefine .. '"')
		end
		return result
	end


--
-- Returns a list of forced include files, decorated for the compiler
-- command line.
--
-- @param cfg
--    The project configuration.
-- @return
--    An array of force include files with the appropriate flags.
--

	function msc.getforceincludes(cfg)
		local result = {}

		table.foreachi(cfg.forceincludes, function(value)
			local fn = project.getrelative(cfg.project, value)
			table.insert(result, "/FI" .. premake.quoted(fn))
		end)

		return result
	end



--
-- Decorate include file search paths for the MSVC command line.
--

	function msc.getincludedirs(cfg, dirs, sysdirs)
		local result = {}
		dirs = table.join(dirs, sysdirs)
		for _, dir in ipairs(dirs) do
			dir = project.getrelative(cfg.project, dir)
			table.insert(result, '-I' ..  premake.quoted(dir))
		end
		return result
	end


--
-- Return a list of linker flags for a specific configuration.
--

	msc.linkerFlags = {
		flags = {
			FatalLinkWarnings = "/WX",
			LinkTimeOptimization = "/GL",
			NoIncrementalLink = "/INCREMENTAL:NO",
			NoManifest = "/MANIFEST:NO",
			OmitDefaultLibrary = "/NODEFAULTLIB",
			Symbols = "/DEBUG",
		},
		kind = {
			SharedLib = "/DLL",
		}
	}

	msc.librarianFlags = {
		flags = {
			FatalLinkWarnings = "/WX",
		}
	}

	function msc.getldflags(cfg)
		local map = iif(cfg.kind ~= premake.STATICLIB, msc.linkerFlags, msc.librarianFlags)
		local flags = config.mapFlags(cfg, map)
		table.insert(flags, 1, "/NOLOGO")
		return flags
	end


--
-- Build a list of additional library directories for a particular
-- project configuration, decorated for the tool command line.
--
-- @param cfg
--    The project configuration.
-- @return
--    An array of decorated additional library directories.
--

	function msc.getLibraryDirectories(cfg)
		local flags = {}
		local dirs = table.join(cfg.libdirs, cfg.syslibdirs)
		for i, dir in ipairs(dirs) do
			dir = project.getrelative(cfg.project, dir)
			table.insert(flags, '/LIBPATH:"' .. dir .. '"')
		end
		return flags
	end


--
-- Return the list of libraries to link, decorated with flags as needed.
--

	function msc.getlinks(cfg)
		local links = config.getlinks(cfg, "system", "fullpath")
		for i = 1, #links do
			links[i] = path.appendextension(links[i], ".lib")
		end
		return links
	end


--
-- Returns makefile-specific configuration rules.
--

	function msc.getmakesettings(cfg)
		return nil
	end


--
-- Retrieves the executable command name for a tool, based on the
-- provided configuration and the operating environment.
--
-- @param cfg
--    The configuration to query.
-- @param tool
--    The tool to fetch, one of "cc" for the C compiler, "cxx" for
--    the C++ compiler, or "ar" for the static linker.
-- @return
--    The executable command name for a tool, or nil if the system's
--    default value should be used.
--

	function msc.gettoolname(cfg, tool)
		return nil
	end
