------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                           Explorer_Window_Pkg                            --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision$
--                                                                          --
--                Copyright (C) 2001 Ada Core Technologies, Inc.            --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- GNAT is maintained by Ada Core Technologies Inc (http://www.gnat.com).   --
--                                                                          --
------------------------------------------------------------------------------

with Glib; use Glib;
with Gtk; use Gtk;
with Gtk.Widget;      use Gtk.Widget;
with Gtk.Enums;       use Gtk.Enums;
with Gtk.Clist;       use Gtk.Clist;
with Gtkada.Handlers; use Gtkada.Handlers;
with Callbacks_Aunit_Make_Harness; use Callbacks_Aunit_Make_Harness;
with Aunit_Make_Harness_Intl; use Aunit_Make_Harness_Intl;
with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with Ada.Text_IO; use Ada.Text_IO;
with Gtkada.Types; use Gtkada.Types;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Explorer_Window_Pkg.Callbacks; use Explorer_Window_Pkg.Callbacks;
with Make_Harness_Window_Pkg; use Make_Harness_Window_Pkg;

package body Explorer_Window_Pkg is
   --  Explorer / File browser window definition.  Template
   --  generated by Glade

   procedure Gtk_New (Explorer_Window : out Explorer_Window_Access) is
   begin
      Explorer_Window := new Explorer_Window_Record;
      Explorer_Window_Pkg.Initialize (Explorer_Window);
   end Gtk_New;

   procedure Initialize
     (Explorer_Window : access Explorer_Window_Record'Class) is
      pragma Suppress (All_Checks);
   begin
      Gtk.Window.Initialize (Explorer_Window, Window_Toplevel);
      Return_Callback.Connect
        (Explorer_Window, "delete_event",
         On_Explorer_Window_Delete_Event'Access);
      Set_Title (Explorer_Window, -"Explore");
      Set_Policy (Explorer_Window, False, True, False);
      Set_Position (Explorer_Window, Win_Pos_None);
      Set_Modal (Explorer_Window, False);

      Gtk_New_Vbox (Explorer_Window.Vbox7, False, 0);
      Add (Explorer_Window, Explorer_Window.Vbox7);

      Gtk_New (Explorer_Window.Scrolledwindow1);
      Pack_Start
        (Explorer_Window.Vbox7,
         Explorer_Window.Scrolledwindow1, True, True, 3);
      Set_Policy
        (Explorer_Window.Scrolledwindow1, Policy_Automatic, Policy_Automatic);

      Gtk_New (Explorer_Window.Clist, 2);
      C_List_Callback.Connect
        (Explorer_Window.Clist, "select_row", On_Clist_Select_Row'Access);
      Add (Explorer_Window.Scrolledwindow1, Explorer_Window.Clist);
      Set_Selection_Mode (Explorer_Window.Clist, Selection_Extended);
      Set_Shadow_Type (Explorer_Window.Clist, Shadow_In);
      Set_Show_Titles (Explorer_Window.Clist, False);
      Set_Column_Width (Explorer_Window.Clist, 0, 80);
      Set_Column_Width (Explorer_Window.Clist, 1, 80);
      Set_USize (Explorer_Window.Clist, -1, 190);

      Gtk_New (Explorer_Window.Label4, -("label4"));
      Set_Alignment (Explorer_Window.Label4, 0.5, 0.5);
      Set_Padding (Explorer_Window.Label4, 0, 0);
      Set_Justify (Explorer_Window.Label4, Justify_Center);
      Set_Line_Wrap (Explorer_Window.Label4, False);
      Set_Column_Widget (Explorer_Window.Clist, 0, Explorer_Window.Label4);

      Gtk_New (Explorer_Window.Label5, -("label5"));
      Set_Alignment (Explorer_Window.Label5, 0.5, 0.5);
      Set_Padding (Explorer_Window.Label5, 0, 0);
      Set_Justify (Explorer_Window.Label5, Justify_Center);
      Set_Line_Wrap (Explorer_Window.Label5, False);
      Set_Column_Widget (Explorer_Window.Clist, 1, Explorer_Window.Label5);

      Gtk_New (Explorer_Window.Hbuttonbox2);
      Pack_Start
        (Explorer_Window.Vbox7, Explorer_Window.Hbuttonbox2, False, True, 0);
      Set_Spacing (Explorer_Window.Hbuttonbox2, 30);
      Set_Layout (Explorer_Window.Hbuttonbox2, Buttonbox_Spread);
      Set_Child_Size (Explorer_Window.Hbuttonbox2, 85, 27);
      Set_Child_Ipadding (Explorer_Window.Hbuttonbox2, 7, 0);

      Gtk_New (Explorer_Window.Ok, -"OK");
      Set_Flags (Explorer_Window.Ok, Can_Default);
      Button_Callback.Connect
        (Explorer_Window.Ok, "clicked",
         Button_Callback.To_Marshaller (On_Ok_Clicked'Access));
      Add (Explorer_Window.Hbuttonbox2, Explorer_Window.Ok);

      Gtk_New (Explorer_Window.Cancel, -"Cancel");
      Set_Flags (Explorer_Window.Cancel, Can_Default);
      Button_Callback.Connect
        (Explorer_Window.Cancel, "clicked",
         Button_Callback.To_Marshaller (On_Cancel_Clicked'Access));
      Add (Explorer_Window.Hbuttonbox2, Explorer_Window.Cancel);

   end Initialize;

   ----------
   -- Fill --
   ----------

   procedure Fill
     (Explorer_Window : Explorer_Window_Access)
   is
      --  Fill window list with relevant files.  Annotate entries displayed
      --  in the explorer window with their AUnit kind (test_suite or
      --  test_case)

      Directory    : Dir_Type;
      Buffer       : String (1 .. 256);
      Last         : Natural;
      Dummy        : Gint;

   begin

      GNAT.Directory_Operations.Open
        (Directory, Explorer_Window.Directory.all);
      Clear (Explorer_Window.Clist);

      loop
         Read (Directory, Buffer, Last);
         exit when Last = 0;
         if Is_Directory
           (Explorer_Window.Directory.all
            & Directory_Separator & Buffer (1 .. Last))
         then
            Insert (Explorer_Window.Clist,
                    -1,
                    Null_Array + Buffer (1 .. Last) + "(dir)");
            null;
         else
            --  The third condition eliminates Emacs auto-restore files
            --  from consideration
            if Last > 4
              and then Buffer (Last - 3 .. Last) = ".adb"
              and then Buffer (3) /= '#'
            then
               declare
                  File      : File_Type;
                  Index     : Integer;
                  Index_End : Integer;
                  Line      : String (1 .. 256);
                  Line_Last : Integer;
                  Current_Name : String_Utils.String_Access;
                  Row_Num   : Gint;
               begin
                  Ada.Text_IO.Open (File,
                                    In_File,
                                    Explorer_Window.Directory.all
                                    & Directory_Separator
                                    & Buffer (1 .. Last));
                  loop
                     Get_Line (File, Line, Line_Last);
                     Index := 1;
                     Skip_To_String (To_Lower (Line), Index, "function");
                     if Index < Line_Last - 8 then
                        Index_End := Index;
                        Skip_To_String
                          (To_Lower (Line), Index_End, "access_test_suite");
                        if Index_End < Line_Last - 15 then
                           Index := 1;
                           Skip_To_String
                             (To_Lower (Line), Index, "function ");
                           Index_End := Index + 9;
                           Skip_To_String
                             (To_Lower (Line), Index_End, " return ");
                           Row_Num :=
                             Append (Explorer_Window.Clist,
                                     Null_Array
                                     + Buffer (1 .. Last)
                                     + ("(suite) "
                                        & Line
                                        (Index + 9 .. Index_End - 1)));
                           if Make_Harness_Window.Suite_Name /= null then
                              Free (Make_Harness_Window.Suite_Name);
                           end if;

                           Make_Harness_Window.Suite_Name := new String'
                             (Line (Index + 9 .. Index_End - 1));

                        end if;
                     end if;
                  end loop;
               exception
                  when End_Error =>
                     Close (File);
                     Free (Current_Name);
               end;
            end if;
         end if;
      end loop;

      Dummy := Columns_Autosize (Explorer_Window.Clist);
   exception
      when Directory_Error =>
         null;

   end Fill;

end Explorer_Window_Pkg;