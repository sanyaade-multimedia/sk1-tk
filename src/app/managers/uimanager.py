# -*- coding: utf-8 -*-

# Copyright (C) 2007 by Igor E. Novikov
#
# This library is covered by GNU Library General Public License.
# For more info see COPYRIGHTS file in sK1 root directory.

import app, os, string, math
from app.conf import const
from sk1sdk.libtk import Tkinter
from sk1sdk import tkstyle

	
class UIManager:
	currentColorTheme=None
	root=None
	
	style=None	

	def __init__(self, root=None):
		if not root:
			self.root = Tkinter._default_root
		else:
			self.root=root
		
		self.style=tkstyle.get_system_style(root)
		self.currentColorTheme=self.style.colors		
		tkstyle.set_style(root, self.style)
		self.uploadExtentions()
		self.defineCursors()
		
	def defineCursors(self):
		cur_dir=os.path.join(app.config.sk_share_dir,'cursors')
		setattr(const, 'CurEdit', ('@' + os.path.join(cur_dir,'CurEdit.xbm'),'black'))
		setattr(const, 'CurZoom', ('@' + os.path.join(cur_dir,'CurZoom.xbm'),'black'))
		
	def uploadExtentions(self):
		tcl=os.path.join(app.config.sk_dir,'app','tcl')
		self.root.tk.call('source', os.path.join(tcl,'combobox.tcl'))
		self.root.tk.call('source', os.path.join(tcl,'button.tcl'))
		self.root.tk.call('source', os.path.join(tcl,'tkmenu.tcl'))
		self.root.tk.call('source', os.path.join(tcl,'tkfbox.tcl'))
		self.root.tk.call('source', os.path.join(tcl,'repeater.tcl'))
		self.root.tk.call('source', os.path.join(tcl,'launch_dialog.tcl'))
		
	def setApplicationIcon(self, icon='icon_sk1_16', iconname='sK1'):
		self.root.iconname(iconname)
		self.root.tk.call('wm', 'iconphoto', self.root, icon)
		
	def maximizeApp(self):
		self.root.tk.call('wm', 'attributes', self.root, '-zoomed', 1)	
	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
