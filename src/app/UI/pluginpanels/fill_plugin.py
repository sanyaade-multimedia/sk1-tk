# -*- coding: utf-8 -*-

# Copyright (C) 2008-2009 by Igor E. Novikov
#
# This library is covered by GNU Library General Public License.
# For more info see COPYRIGHTS file in sK1 root directory.

from Ttk import TFrame, TLabel, TCheckbutton
from Tkinter import IntVar
from Tkinter import RIGHT, BOTTOM, X, Y, BOTH, LEFT, TOP, W, E, DISABLED, NORMAL
from app.UI.widgets.colorspacesel import ColorSpaceSelector
from app.UI.widgets.colorchooser import ColorChooserWidget

from app.conf.const import SELECTION, DOCUMENT, EDITED

from app import _, config, Rect
from app.conf import const
import app, copy
from app.UI.tkext import UpdatedButton

from ppanel import PluginPanel

from math import floor, ceil
from app.Graphics import color
from app.Graphics.pattern import SolidPattern

BLACK_COLOR=color.CreateCMYKColor(0,0,0,1)

class FillPanel(PluginPanel):
	name='SolidFill'
	title = _("Solid Fill")
	initial_color=None
	current_color=None


	def init(self, master):
		PluginPanel.init(self, master)
		
		self.initial_color=BLACK_COLOR
		self.current_color = copy.copy(self.initial_color)

		top = TFrame(self.panel, style='FlatFrame', borderwidth=5)
		top.pack(side = TOP, fill=BOTH)

		self.selector=ColorSpaceSelector(top, self.refresh_widgets, self.current_color)
		self.selector.pack(side=TOP, expand = 1, fill=X)
		
		self.picker=ColorChooserWidget(top)
		self.picker.pack(side=TOP, expand = 1, fill=X)		


		button = UpdatedButton(top, text = _("Apply"),
								command = self.apply_pattern,
								sensitivecb = self.is_selection)
		button.pack(side = BOTTOM, expand = 1, fill = X)
		self.Subscribe(SELECTION, button.Update)
		
		button = UpdatedButton(top, text = _("Copy From..."),
								command = self.copy_from,
								sensitivecb = self.is_selection)
		button.pack(side = BOTTOM, expand = 1, fill = X, pady=5)
		self.Subscribe(SELECTION, button.Update)
		
		self.var_autoupdate = IntVar(top)
		self.var_autoupdate.set(1)
		
		self.autoupdate_check = TCheckbutton(top, text = _("Auto Update"), 
												variable = self.var_autoupdate)
		self.autoupdate_check.pack(side = BOTTOM, anchor=W, padx=5, pady=5)
				
		self.document.Subscribe(SELECTION, self.init_from_doc)	
		self.document.Subscribe(EDITED, self.init_from_doc)
		self.init_from_doc()

###############################################################################
	def is_selection(self):
		return (len(self.document.selection) > 0)


	def init_from_doc(self, *arg):
		self.Update()
		self.issue(SELECTION)

	def Update(self):
		self.initial_color = self.get_object_color()
		self.current_color = copy.copy(self.initial_color)		
		self.refresh_widgets(self.current_color)
	
	def refresh_widgets(self, color):
		self.current_color=color
		self.selector.set_color(self.current_color)
		self.picker.set_color(self.current_color)


	def apply_pattern(self):
		pass


	def copy_from(self):
		pass
	
	def get_object_color(self):
		properties = 0
		if self.document.HasSelection():
			properties = self.document.CurrentProperties()
		else:
			return BLACK_COLOR
		if properties and properties.HasFill() and properties.fill_pattern.__class__ == SolidPattern:
			return properties.fill_pattern.Color()	
		else:
			return None

instance=FillPanel()
app.objprop_plugins.append(instance)
