# -*- coding: utf-8 -*-

# Copyright (C) 2007 by Igor E. Novikov
#
# This library is covered by GNU Library General Public License.
# For more info see COPYRIGHTS file in sK1 root directory.

import Tkinter, app, os, string, math
from app.utils import os_utils
from app.utils import locale_utils
from app import _


def convertForKdialog(filetypes):
	'''This function converts filetypes tuple into string
	in kdialog format
	'''
	result=''
	for filetype in filetypes:
		descr=filetype[0]
		extentions=filetype[1]
		for extention in extentions:
			result+=extention+' '
		result+='|'+descr+' \n'		
	return result

openfiletypes=((_('sK1 vector graphics files - *.sK1'),('*.sK1', '*.sk1', '*.SK1')))

importfiletypes=((_('All supported files - *.sk1 *.sk *.ai *.eps *.cdr *.svg *.wmf etc. '),
				  ('*.sK1', '*.sk1', '*.SK1', '*.sk', '*.SK', '*.ai', '*.AI', '*.eps', '*.EPS', '*.ps', '*.PS',
					'*.cmx', '*.CMX', '*.cdr', '*.CDR', '*.cdt', '*.CDT', '*.ccx', '*.CCX', '*.cgm', 
					'*.CGM', '*.aff', '*.AFF', '*.svg', '*.SVG', '*.wmf', '*.WMF', '*.fig', '*.FIG')),
				 (_('sK1 vector graphics files - *.sk1'),('*.sK1', '*.sk1', '*.SK1')),
				 (_('Sketch\Skencil files - *.sk'),('*.sk', '*.SK')),
				 (_('Adobe Illustrator files (up to ver. 9.0) - *.ai'),('*.ai', '*.AI')),
				 (_('Encapsulated PostScript files - *.eps'),('*.eps', '*.EPS')),
				 (_('PostScript files - *.ps'),('*.ps', '*.PS')),
				 (_('CorelDRAW Graphics files (7-X3 ver.) - *.cdr'),('*.cdr', '*.CDR')),
				 (_('CorelDRAW Templates files (7-X3 ver.) - *.cdt'),('*.cdt', '*.CDT')),
				 (_('CorelDRAW Presentation Exchange files - *.cmx'),('*.cmx', '*.CMX')),
				 (_('CorelDRAW Compressed Exchange files (CDRX format) - *.ccx'),('*.ccx', '*.CCX')),
				 (_('Computer Graphics Metafile files - *.cgm'),('*.cgm', '*.CGM')),
				 (_('Acorn Draw files - *.aff'),('*.aff', '*.AFF')),
				 (_('Scalable Vector Graphics files - *.svg'),('*.svg', '*.SVG')),
				 (_('Windows Metafile files - *.wmf'),('*.wmf', '*.WMF')),				 
				 (_('XFig files - *.fig'),('*.fig', '*.FIG')))

savefiletypes=((_('sK1 vector graphics files - *.sK1'),('*.sK1', '*.sk1', '*.SK1')))

exportfiletypes=((_('sK1 vector graphics files - *.sK1'),('*.sK1', '*.sk1', '*.SK1')),
				 (_('Sketch and Skencil files - *.sk'),('*.sk', '*.SK')),
				 (_('Adobe Illustrator files (ver. 5.0) - *.ai'),('*.ai', '*.AI')),
				 (_('Computer Graphics Metafile files - *.cgm'),('*.cgm', '*.CGM')),
				 (_('Scalable Vector Graphics files - *.svg'),('*.svg', '*.SVG')),
				 (_('Windows Metafile files - *.wmf'),('*.wmf', '*.WMF')))

imagefiletypes=((_('All supported files - *.png *.jpg *.tif *.gif *.psd *.bmp *.pcx etc.'),
				 ('*.png', '*.PNG', '*.gif', '*.GIF', '*.jpg', '*.JPG', '*.jpeg', '*.JPEG', '*.tif', '*.TIF',
				  '*.tiff', '*.TIFF', '*.gif', '*.GIF', '*.bmp', '*.BMP', '*.pcx', '*.PCX', '*.pbm', '*.PBM',
				  '*.pgm', '*.PGM', '*.ppm', '*.PPM', '*.eps', '*.EPS')),
				(_('Portable Network Graphics files - *.png'),('*.png', '*.PNG')),
				(_('Encapsulated PostScript files - *.eps'),('*.eps', '*.EPS')),
				(_('JPEG files - *.jpg *jpeg'),('*.jpg', '*.JPG', '*.jpeg', '*.JPEG')),
				(_('TIFF files - *.tif *.tiff'),('*.tif', '*.TIF', '*.tiff', '*.TIFF')),
				(_('CompuServ Graphics files - *.gif'),('*.gif', '*.GIF')),
				(_('Adobe Photoshop files (up to v.3.0) - *.psd'),('*.psd', '*.PSD')),
				(_('Windows Bitmap files - *.bmp'),('*.bmp', '*.BMP')),
				(_('Paintbrush files - *.pcx'),('*.pcx', '*.PCX')),
				(_('Portable Bitmap files - *.pbm'),('*.pbm', '*.PBM')),
				(_('Portable Graymap files - *.pgm'),('*.pgm', '*.PGM')),
				(_('Portable Pixmap files - *.ppm'),('*.ppm', '*.PPM')))

KDE_DIALOG=1
GNOME_DIALOG=2
TK_DIALOG=3

SAVEMODE=1
OPENMODE=0

class DialogManager:
	#0- unknown; 1- KDE; 2- Gnome
	root=None
	desktop=0
	dialogObject=None
	is_kdialog=0
	is_zenity=0
	def __init__(self, root):
		self.root=root
		self.check_enviroment()
		self.validate_binaries()
	
	def check_enviroment(self):
		ds=os_utils.getenv('DESKTOP_SESSION')
		if ds:
			if string.find(string.upper(ds), 'KDE')>0:
				self.desktop=1
			else:
				if string.find(string.upper(ds), 'GNOME')>0:
					self.desktop=2
				else:
					self.desktop=0
		else:
			self.desktop=0
	
	def validate_binaries(self):
		if os.path.isfile('/usr/bin/kdialog'):
			self.is_kdialog=1
		else:
			self.is_kdialog=0
		if os.system('zenity --help-misc>/dev/null'):
			self.is_zenity=0
		else:
			self.is_zenity=1
			
	def get_dialog_type(self, mode):
		dialog_mode=app.config.preferences.dialog_type
		if not dialog_mode:
			if not self.desktop:
				dialog_type=TK_DIALOG
			else:
				dialog_type=self.desktop
		else:
			dialog_type=dialog_mode
		if dialog_type==KDE_DIALOG and self.is_kdialog==0:
			dialog_type==TK_DIALOG
		if dialog_type==GNOME_DIALOG and self.is_zenity==0:
			dialog_type==TK_DIALOG			
		if mode==SAVEMODE:
			if dialog_type==KDE_DIALOG:
				return KDE_GetSaveFilename
			if dialog_type==GNOME_DIALOG:
				return Gnome_GetSaveFilename
			if dialog_type==TK_DIALOG:
				return TkGetSaveFilename
		if mode==OPENMODE:
			if dialog_type==KDE_DIALOG:
				return KDE_GetOpenFilename
			if dialog_type==GNOME_DIALOG:
				return Gnome_GetOpenFilename
			if dialog_type==TK_DIALOG:
				return TkGetOpenFilename
			
	def getOpenFilename(self, **kw):
		name=app.config.name
		title=_('Open file')
		kw['filetypes']=openfiletypes
		dialog_type=self.get_dialog_type(OPENMODE)
		return apply(dialog_type, (self.root, name, title), kw)
		
	def getSaveFilename(self, **kw):
		name=app.config.name
		title=_('Save file')
		kw['filetypes']=savefiletypes
		dialog_type=self.get_dialog_type(SAVEMODE)
		return apply(dialog_type, (self.root, name, title), kw)

	def getSaveAsFilename(self, **kw):
		name=app.config.name
		title=_('Save file As...')
		kw['filetypes']=savefiletypes
		dialog_type=self.get_dialog_type(SAVEMODE)
		return apply(dialog_type, (self.root, name, title), kw)
	
def TkGetOpenFilename(master, name, title, **kw):
	''' Calls regular Tk open file dialog.
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	filetypes - tuple of file types (see examples in the package)
	
	Returns: tuple of utf8 and system encoded file names
	'''
	kw['title']=name+' - '+title
	filename = apply(master.tk.call, ('tk_getOpenFile', '-parent', master._w) + master._options(kw))
	return master.tk.utf8_to_system(filename)

def TkGetSaveFilename(master, name, title, **kw):
	''' Calls regular Tk save file dialog.
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	initialfile - file name
	filetypes - tuple of file types (see examples in the package)
	
	Returns: tuple of utf8 and system encoded file names
	'''
	kw['title']=name+' - '+title
	filename = apply(master.tk.call, ('tk_getSaveFile', '-parent', master._w) + master._options(kw))
	return (filename, master.tk.utf8_to_system(filename))

def KDE_GetOpenFilename(master, name, title, **kw):
	''' Calls KDE open file dialog.   .rstrip("\n")
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	filetypes - tuple of file types (see examples in the package)
	
	Returns: tuple of utf8 and system encoded file names
	'''
	initialdir=kw['initialdir']
	filetypes=convertForKdialog(kw['filetypes'])	
	master.update()
	winid=str(master.winfo_id())	
	from_K = os.popen('kdialog --caption \''+title+'\' --embed \''+winid+'\' --name \''+name+'\' --getopenfilename \''+initialdir+'\''+ filetypes)
	file=from_K.readline()
	filename=locale_utils.strip_line(file)
	from_K.close()
	return (master.tk.system_to_utf8(filename), filename)

def KDE_GetSaveFilename(master, name, title, **kw):
	''' Calls KDE save file dialog.   
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	filetypes - tuple of file types (see examples in the package)
	
	Returns: tuple of utf8 and system encoded file names
	'''
	initialdir=kw['initialdir']
	filetypes=convertForKdialog(kw['filetypes'])	
	master.update()
	winid=str(master.winfo_id())
	#--name='title'
	from_K = os.popen('kdialog -caption \''+title+'\' --embed \''+winid+'\' --getsavefilename \''+initialdir+'\''+ filetypes)
	file=from_K.readline()
	filename=locale_utils.strip_line(file)
	from_K.close()
	return (master.tk.system_to_utf8(filename), filename)

def Gnome_GetOpenFilename(master, name, title, **kw):
	''' Calls Gnome open file dialog.   
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	
	Returns: tuple of utf8 and system encoded file names
	'''
	print 'TRACE GNOME'
	initialdir=kw['initialdir']
	master.update()
	winid=str(master.winfo_id())
	name+=' - '+title
	print name
	from_K = os.popen('zenity --file-selection --name="'+name+'" --filename="'+initialdir+'"')
	file=from_K.readline()
	filename=locale_utils.strip_line(file)
	from_K.close()
	return (master.tk.system_to_utf8(filename), filename)

def Gnome_GetSaveFilename(master, name, title, **kw):
	#zenity --file-selection --filename='print4.eps' --save
	''' Calls Gnome open file dialog.   
	Parameteres:
	master - parent window
	name - application name
	title - dialog title
	**kw:
	initialdir - absolute path to initial dir
	initialfile - file name
	
	Returns: tuple of utf8 and system encoded file names
	'''
	initialdir=kw['initialdir']
	initialfile=kw['initialfile']
	master.update()
	winid=str(master.winfo_id())
	name+=' - '+title
	from_K = os.popen('zenity --file-selection --save --name=\''+name+'\' --filename=\''+os.path.join(initialdir,initialfile)+'\'')
	file=from_K.readline()
	filename=locale_utils.strip_line(file)
	from_K.close()
	return (master.tk.system_to_utf8(filename), filename)
	