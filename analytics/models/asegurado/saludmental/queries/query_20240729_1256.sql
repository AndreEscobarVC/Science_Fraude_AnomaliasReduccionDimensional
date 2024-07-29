--------------------------------------------------------------------------------
------------------------ CLASIFICACION PRESTACIONES ----------------------------
--------------------------------------------------------------------------------

drop table if exists #clasif
select  dp.CodigoPrestacion,
        dp.GlosaPrestacionHomologada,
		gp.IdGrupoPrestacion,
		gp.ClasificacionGrupo,
		sp.IdSubgrupoPrestacion,
		sp.ClasificacionSubgrupo,
		ap.IdAperturaPrestacion,
		ap.ClasificacionApertura
into #clasif
from [datalake].[Prestacion].[DetallePrestacion] dp
inner join [datalake].[Prestacion].[SubgrupoAperturaPrestacion] sap ON sap.IdSubgrupoApertura = dp.IdSubgrupoApertura and dp.Vigencia = 1 and sap.Vigencia = 1
inner join [datalake].[Prestacion].[GrupoSubgrupoPrestacion] gsp ON gsp.IdGrupoSubgrupo = dp.IdGrupoSubgrupo and gsp.Vigencia = 1
inner join [datalake].[Prestacion].[GrupoPrestacion] gp ON gp.IdGrupoPrestacion = gsp.IdGrupoPrestacion and gp.Vigencia = 1
inner join [datalake].[Prestacion].[SubgrupoPrestacion] sp ON (sp.IdSubgrupoPrestacion = sap.IdSubgrupoPrestacion) and (sp.IdSubgrupoPrestacion = gsp.IdSubgrupoPrestacion) and sp.Vigencia = 1
inner join [datalake].[Prestacion].[AperturaPrestacion] ap ON ap.IdAperturaPrestacion = sap.IdAperturaPrestacion and ap.Vigencia = 1
inner join [datalake].[Prestacion].[PatologiaAsociada] pa ON pa.IdPatologiaAsociada = dp.IdPatologiaAsociada and pa.Vigencia = 1

--------------------------------------------------------------------------------
------------------------ PERSONAS ----------------------------------------------
--------------------------------------------------------------------------------

declare @fechadesde as datetime = '20240601'
declare @fechahasta as datetime = '20240701'

drop table if exists #siniestros0

select distinct sin.RutTitular, sin.fecharecepcionliquidacionvc as FechaRecepcionLiquidacion, 
				cast(sd2.CodigoBeneficio as int) CodigoBeneficio, 
				cla.IdGrupoPrestacion, cla.ClasificacionGrupo, 
				cla.IdSubgrupoPrestacion, cla.ClasificacionSubgrupo, 
				cla.IdAperturaPrestacion, cla.ClasificacionApertura,
				ig.Glosa GlosaBeneficio

into #siniestros0

from bos.bos.siniestro sin

inner join bos.bos.denuncio den on den.iddenuncio = sin.iddenuncio and sin.vigente = 1 and sin.fecharecepcionliquidacionvc >= @fechadesde and sin.fecharecepcionliquidacionvc < @fechahasta and sin.FechaSiniestro >= @fechadesde and sin.IdPlanBeneficio not like 'DEN%'
inner join bos.bos.siniestrodocumento sd on sd.idsiniestro = sin.idsiniestro
inner join bos.bos.liquidaciondetalle sd2 on sd2.idSiniestroDocumento=sd.idSiniestroDocumento and sd2.IdLiquidacionDetalleEstado = 1

inner join bos.bos.liquidacion liq on liq.idSiniestro = sin.idSiniestro

inner join bos.bos.categorizacioncanal cat on sin.IdCanal = cat.IdCanal and sin.IdDenuncioClasificacion = cat.IdDenuncioClasificacion and sin.IdDenuncioTipo = cat.IdDenuncioTipo
																
																		and cat.IdCategorizacionCanal <> 5  -- dental
																		and cat.IdCategorizacionCanal <> 11 -- dental
																		and cat.IdCategorizacionCanal <> 14 -- dental
																		and cat.IdCategorizacionCanal <> 27 -- dental
			    
																		and cat.IdCategorizacionCanal <> 3  -- medicamentos 
																		and cat.IdCategorizacionCanal <> 9  -- medicamentos 
																		and cat.IdCategorizacionCanal <> 29 -- medicamentos
																		and cat.IdCategorizacionCanal <> 30 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 31 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 32 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 44 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 45 -- medicamentos 

																		and cat.IdCanal <> 9								-- Quito Denuncia Liquidador
																		and cat.IdDenuncioTipo <> 2							-- Quito Dental
																		and cat.IdDenuncioTipo <> 4 and cat.IdCanal <> 2	-- Quito Medicamentos 
																		and cat.IdCanal <> 7								-- Quito Consalud
																		and cat.IdCanal <> 6								-- Quito Medipass
																		and cat.IdCanal <> 5 and cat.IdDenuncioTipo <> 5	-- Quito los OP

inner join bos.bos.prestadorsucursal ps on sd.idprestadorsucursal = ps.idprestadorsucursal
inner join bos.bos.prestador pre on ps.idprestador = pre.idprestador 
inner join suscripcion.dbo.isapre isa on isa.idIsapre = sin.IdPrevisionAsegurado and isa.vigente = 1

inner join AUS.Siniestralidad.InstanciaGeneral ig on ig.Codigo=sd2.IdGrupo and (ig.codigo <> 300 and ig.codigo <> 700 and ig.codigo <> 800 and ig.codigo <> 900)
left join #clasif cla on cast(cla.CodigoPrestacion as int) = cast(sd2.CodigoBeneficio as int)

drop table if exists #titulares
select RutTitular, max(FechaRecepcionLiquidacion) LiquidacionHasta, 
	   dateadd(year, -1, max(FechaRecepcionLiquidacion)) LiquidacionDesde, 
	   dateadd(month, -1, max(FechaRecepcionLiquidacion)) PrestacionDesde
into #titulares
from #siniestros0 
where GlosaBeneficio = 'BENEFICIOS DE SALUD MENTAL' or ClasificacionSubgrupo = 'SALUD MENTAL'
group by RutTitular

--------------------------------------------------------------------------------
----------------------------- SINIESTROS -----------------------------------------
--------------------------------------------------------------------------------

drop table if exists #siniestros1

select  sin.RutTitular, sin.fecharecepcionliquidacionvc as FechaRecepcionLiquidacion, 
		cast(sd2.CodigoBeneficio as int) CodigoBeneficio, 
		cla.IdGrupoPrestacion, cla.ClasificacionGrupo, 
		cla.IdSubgrupoPrestacion, cla.ClasificacionSubgrupo, 
		cla.IdAperturaPrestacion, cla.ClasificacionApertura,
		ig.Glosa GlosaBeneficio

into #siniestros1

from bos.bos.siniestro sin

inner join #titulares t on t.RutTitular = sin.RutTitular and (sin.FechaRecepcionLiquidacionVC between t.LiquidacionDesde and t.LiquidacionHasta) and (sin.FechaSiniestro >= t.PrestacionDesde)

inner join bos.bos.denuncio den on den.iddenuncio = sin.iddenuncio and sin.vigente = 1 and sin.IdPlanBeneficio not like 'DEN%'

inner join bos.bos.siniestrodocumento sd on sd.idsiniestro = sin.idsiniestro
inner join bos.bos.liquidaciondetalle sd2 on sd2.idSiniestroDocumento=sd.idSiniestroDocumento and sd2.IdLiquidacionDetalleEstado = 1

inner join bos.bos.liquidacion liq on liq.idSiniestro = sin.idSiniestro

inner join bos.bos.categorizacioncanal cat on sin.IdCanal = cat.IdCanal and sin.IdDenuncioClasificacion = cat.IdDenuncioClasificacion and sin.IdDenuncioTipo = cat.IdDenuncioTipo
																
																		and cat.IdCategorizacionCanal <> 5  -- dental
																		and cat.IdCategorizacionCanal <> 11 -- dental
																		and cat.IdCategorizacionCanal <> 14 -- dental
																		and cat.IdCategorizacionCanal <> 27 -- dental
			    
																		and cat.IdCategorizacionCanal <> 3  -- medicamentos 
																		and cat.IdCategorizacionCanal <> 9  -- medicamentos 
																		and cat.IdCategorizacionCanal <> 29 -- medicamentos
																		and cat.IdCategorizacionCanal <> 30 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 31 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 32 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 44 -- medicamentos 
																		and cat.IdCategorizacionCanal <> 45 -- medicamentos 

																		and cat.IdCanal <> 9								-- Quito Denuncia Liquidador
																		and cat.IdDenuncioTipo <> 2							-- Quito Dental
																		and cat.IdDenuncioTipo <> 4 and cat.IdCanal <> 2	-- Quito Medicamentos 
																		and cat.IdCanal <> 7								-- Quito Consalud
																		and cat.IdCanal <> 6								-- Quito Medipass
																		and cat.IdCanal <> 5 and cat.IdDenuncioTipo <> 5	-- Quito los OP

inner join bos.bos.prestadorsucursal ps on sd.idprestadorsucursal = ps.idprestadorsucursal
inner join bos.bos.prestador pre on ps.idprestador = pre.idprestador 
inner join suscripcion.dbo.isapre isa on isa.idIsapre = sin.IdPrevisionAsegurado and isa.vigente = 1

inner join AUS.Siniestralidad.InstanciaGeneral ig on ig.Codigo=sd2.IdGrupo and (ig.codigo <> 300 and ig.codigo <> 700 and ig.codigo <> 800 and ig.codigo <> 900)
left join #clasif cla on cast(cla.CodigoPrestacion as int) = cast(sd2.CodigoBeneficio as int)

select * 
from #siniestros1 
order by RutTitular