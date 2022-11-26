*******************************************************************************************
*工具变量法
*Note: there are 111 countries in the world sample that have all the necessary data to run the below regressions, though the paper only reports 110 observations. I'm not sure which of the 111 observations is not used in the paper, so the regressions below will use all 111 obs. and won't quite match the results reported in the paper. 
use maketable8,clear
rename logpgp95 logGDP
rename avexpr institutions
rename lat_abst latitude
rename logem4 logMortality
keep logGDP institutions logMortality latitude euro1900 shortnam

*OLS的回归结果
reg logGDP institutions latitude, r
est store m1

*IV-2SLS
ivregress 2sls logGDP latitude (institutions=logMortality), first
est store m2

*Hausman检验解释变量的外生性
estat endogenous

*弱工具变量检验
estat firststage

*检验工具变量是否是外生的(过度识别检验)
ivregress 2sls logGDP latitude (institutions=logMortality euro1900), first
estat overid

对比OLS与IV

*OLS的回归结果
qui:reg logGDP institutions latitude, r
est store m1
*IV-2SLS
qui:ivregress 2sls logGDP latitude (institutions=logMortality), first
est store m2
local mlist_1 "m1 m2" 
esttab `mlist_1' , scalars(N r2) noconstant replace  mtitles("OLS" "IV")

*******************************************************************************************
*Heckman两步法
use womenwk.dta, clear 

*方法1：手动估计
probit work education age children //估计D=1的概率
predict z if e(sample), xb //用probit得到的系数计算z=γ0+γ1Education+γ2Age+γ3Children
gen phi = normalden(z)     //计算对应的正态分布的概率密度值
gen PHI = normal(z)        //计算对应的正态分布的累积分布值
gen IMR = phi/PHI          //计算逆米尔斯比率
reg  wage education age IMR if work == 1  //女性工作子样本
est store sd

*方法2：使用Stata的Heckman命令
heckman wage education age, select(education age children) twostep
est store zd

*对比两种方法
local m "sd zd"
esttab `m', scalars(N r2) noconstant replace mtitle("手动估计" "Heckman") nogap compress pr2 ar2
**********************************************************************************************
*倾向得分匹配
use ldw_exper.dta,clear

*OLS
reg re78 t age educ black hisp married re74 re75 u74 u75, r
est store psm1
*PSM
set seed 10101
gen ranorder = runiform()
sort ranorder

psmatch2 t age educ black hisp married re74 re75 u74 u75, outcome (re78) n(1) ate ties logit common
est store psm2

bootstrap r(att) r(atu) r(ate), reps(500): psmatch2 t age educ black hisp married re74 re75 u74 u75, outcome (re78 ) n(1) ate ties logit common //自助法求标准误

quietly psmatch2 t age educ black hisp married re74 re75 u74 u75, outcome (re78) n(1) ate ties logit common
pstest age educ black hisp married re74 re75 u74 u75, both graph //平衡性检验

psgraph //倾向得分的共同取值范围



************************************************************************************************
*断点回归
use 养老金.dta, clear
net install rdrobust, from(https://sites.google.com/site/rdpackages/rdrobust/stata) replace

rdplot nrps_get agesd, binselect(es) ci(95) nbins(15) graph_options(ytitle(获得养老金的概率) xtitle(标准化年龄) graphregion(color(white)))


rdplot f_burden agesd, binselect(es) ci(95) nbins(15) ///
   graph_options(ytitle("自负-收入比") ///
                 xtitle("标准化年龄") ///
                 graphregion(color(white))) //年龄与自负—收入比主回归

rdplot cata_medi agesd, binselect(es) ci(95) nbins(15) ///
   graph_options(ytitle("发生灾难性卫生支出") ///
                 xtitle("标准化年龄") ///
                 graphregion(color(white))) //年龄与灾难性医疗支出主回归


**** panelA
rdrobust f_burden agesd , fuzzy(nrps_get)  bwselect(msesum) ///
   covs(Edu Marry_Status body_pain hypertension chro_disease_num  GH_poor_2 memory_sr_poor  ADL_IADL Y2_CESD_score insured) ///
   vce(cluster householdID)  
**** panelB   
rdrobust cata_medi agesd , fuzzy(nrps_get)  bwselect(msesum) ///
   covs(Edu Marry_Status body_pain hypertension chro_disease_num  GH_poor_2 memory_sr_poor  ADL_IADL Y2_CESD_score insured) ///
   vce(cluster householdID)

**************************************************************************************************
*固定效应
use MainResult.dta clear

xtset id year        
xtreg lngdp did i.year, fe 





