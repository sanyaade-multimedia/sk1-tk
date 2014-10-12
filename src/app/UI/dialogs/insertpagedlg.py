# -*- coding: utf-8 -*-

# Copyright (C) 2008 by Igor E. Novikov
#
# This library is covered by GNU Library General Public License.
# For more info see COPYRIGHTS file in sK1 root directory.

from app import _
import app
from dialog import ModalDialog
from msgdialog import msgDialog

from sk1sdk.libttk import TButton, TLabel, TFrame
from app.UI.ttk_ext import TSpinbox
from app.UI.tkext import UpdatedRadiobutton
from Tkinter import StringVar
from Tkinter import TOP, LEFT, RIGHT, BOTTOM, X, BOTH, W

class InsertPageDialog(ModalDialog):

	class_name = 'InsertPageDialog'
	
	def __init__(self, master, is_before = 0, dlgname = '__dialog__'):
		self.master=master
		self.title = _("Insert pages")
		self.is_before=is_before
		self.init_vars()
		ModalDialog.__init__(self, master, name = dlgname)
		
	def init_vars(self):
		self.numpages=StringVar(self.master)
		self.numpages.set('1')
		self.pagenum=StringVar(self.master)
		self.pagenum.set('%u'%(app.mw.document.active_page+1))
	
	def build_dlg(self):
		root = TFrame(self.top, style='FlatFrame', borderwidth = 10)
		root.pack(side = TOP, fill = BOTH, expand = 1)
		
		top = TFrame(root, style='FlatFrame', borderwidth = 5)
		top.pack(side = TOP, fill = X, expand = 1)
		label = TLabel(top, text = _("Insert:")+" ", style='FlatLabel')
		label.pack(side = LEFT)
		self.numpages_spin = TSpinbox(top,  var=1, vartype=0, textvariable = self.numpages,
						min = 1, max = 1000, step = 1, width = 6, command = self.ok)
		self.numpages_spin.pack(side = LEFT)		
		label = TLabel(top, text = " "+_("page(s)"), style='FlatLabel')
		label.pack(side = LEFT)


		middle = TFrame(root, style='FlatFrame', borderwidth = 5)
		middle.pack(side = TOP, fill = X, expand = 1)
		
		rbframe = TFrame(middle, style='FlatFrame', borderwidth = 5)
		rbframe.pack(side = LEFT)
		self.var_reference = StringVar(self.master)
		if self.is_before:
			self.var_reference.set('before')
		else:
			self.var_reference.set('after')			
		radio = UpdatedRadiobutton(rbframe, value = 'before', text = _("Before")+" ", variable = self.var_reference)
		radio.pack(side=TOP, anchor=W)
		radio = UpdatedRadiobutton(rbframe, value = 'after', text = _("After")+" ", variable = self.var_reference)
		radio.pack(side=TOP, anchor=W)	
		
		label = TLabel(middle, text = " "+_("page No.:")+" ", style='FlatLabel')
		label.pack(side = LEFT)
		self.pagenum_spin = TSpinbox(middle, var=app.mw.document.active_page+1, vartype=0, textvariable = self.pagenum,
						min = 1, max = len(app.mw.document.pages), step = 1, width = 6, command = self.ok)
		self.pagenum_spin.pack(side = LEFT)
		if len(app.mw.document.pages)==1:
			self.pagenum_spin.set_state('disabled')
			

		bottom = TFrame(root, style='FlatFrame', borderwidth = 5)
		bottom.pack(side = BOTTOM, fill = X, expand = 1)
		cancel = TButton(bottom, text=_("Cancel"), command=self.cancel)
		cancel.pack(side = RIGHT)

		label = TLabel(bottom, text = '  ', style='FlatLabel')
		label.pack(side = RIGHT)
		ok = TButton(bottom, text=_("OK"), command=self.ok)
		ok.pack(side = RIGHT)
		self.focus_widget = ok
		
		self.top.bind('<Escape>', self.cancel)
		self.top.protocol('WM_DELETE_WINDOW', self.cancel)		
		self.top.resizable (width=0, height=0)
	
	def ok(self, *arg):
		is_before=0
		if not 0 <= self.pagenum_spin.get_value()-1 < len(app.mw.document.pages):
			msgDialog(self.top, title = _("Error"), message = _('Incorrect page number!'))
			self.pagenum_spin.entry.focus_set()
			return
		if not 0 < self.numpages_spin.get_value():
			msgDialog(self.top, title = _("Error"), message = _('Incorrect number of pages!'))
			self.numpages_spin.entry.focus_set()
			return
		if self.var_reference.get()=='before':
			is_before=1
		app.mw.document.InsertPages(number=self.numpages_spin.get_value(), 
								index=self.pagenum_spin.get_value()-1, 
								is_before=is_before)
		self.close_dlg()
	
	def cancel(self, *arg):
		self.close_dlg(None)
		
def insertpgDialog(master, is_before = 0):
	dlg = InsertPageDialog(master, is_before)
	dlg.RunDialog()
