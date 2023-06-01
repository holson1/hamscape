function add_new_dust(_x,_y,_dx,_dy,_l,_s,_g,_f)
    add(dust, {
    fade=_f,x=_x,y=_y,dx=_dx,dy=_dy,life=_l,orig_life=_l,rad=_s,col=8,grav=_g,draw=function(self)
    pal()palt()circfill(self.x,self.y,self.rad,self.col)
    end,update=function(self)
    self.x+=self.dx self.y+=self.dy
    self.dy+=self.grav self.rad*=0.9 self.life-=1
    if type(self.fade)=="table"then self.col=self.fade[flr(#self.fade*(self.life/self.orig_life))+1]else self.col=self.fade end
    if self.life<0then del(dust,self)end end})
end