#define V(a,b,o)(v){a.x o b.x,a.y o b.y,a.z o b.z}
#define A(x)sizeof(x)/sizeof(*x)
#define R return
#define F(v,m)for(int v=0;v<m;v++)
X=800;Y=600;typedef float f;typedef struct{f x,y,z;}v;struct{v d;f c[3];}L[]={{{
4,-6,1},{1,1,1}},{{-3,-1,.2},{1,.3,0}}};f S[]={0,.3,.6};O[]={81,74,68,10,81};W=7
;f d(v a,v b){R a.x*b.x+a.y*b.y+a.z*b.z;}f q(f x){R x<0?0:x>1?1:x;}v M(f x,v y){
R(v){x*y.x,x*y.y,x*y.z};}v s(v x){R M(1/sqrt(d(x,x)),x);}f _(v g,v w,int c,int x
){if(x>9)R 0;w=s(w);f t=99,a,b,m,z;v r,n,p;F(i,A(O))F(j,W)if(O[i]&(1<<j)){v p={2
*j-W+1,A(O)-2.*i-1,12};n=V(g,p,-);b=d(n,w);a=d(n,n)-1;z=sqrt(b*b-a);m=-fabs(z)-b
;if(m<t&&m>.01){t=m;r=p;if(x<0)R 1;}}if(t>98){t=(-g.y-A(O))/w.y;R t>0?(c>1)*fabs
(sin(t/42)):x<0?0:S[c];}p=V(g,t*w,+);n=s(V(p,r,-));a=0;F(i,A(L)){r=M(-1,s(L[i].d
));a+=_(p,r,0,-1)?0:L[i].c[c]*(q(d(n,r))+pow(q(d(V(r,M(2*d(r,n),n),-),w)),42));}
R q(a+_(p,V(w,M(2*d(w,n),n),-),c,x+1)/2);}main(){printf("P6 %i %i 255\n",X,Y);F(
y,Y)F(x,X)F(i,3)putchar((int)(_((v){0,0,0},(v){(x-X/2.)/Y,(Y/2.-y)/Y,1},i,0)*255
));}
