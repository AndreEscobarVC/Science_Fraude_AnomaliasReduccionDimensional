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

select	case when sin.RutTitular = sin.RutSiniestrado then 'Titular' else 'Carga' end RolPersona,
		sin.RutTitular, case when p.sexo = 'F' then 1 else 0 end TitularFemenino, datediff(day, p.fechanacimiento, sd2.fechabeneficio)/365 EdadTitular,
		sin.RutSiniestrado, case when pb.sexo = 'F' then 1 else 0 end SiniestradoFemenino, datediff(day, pb.fechanacimiento, sd2.fechabeneficio)/365 EdadSiniestrado,
		
		case when isa.glosa = 'FONASA' then 'FONASA' else 'NO FONASA' end Prevision,

		den.NumeroDenuncio as NumeroSolicitud,
		sin.fecharecepcionliquidacionvc as FechaRecepcionLiquidacion, 
			
		cast(sd2.CodigoBeneficio as int) CodigoBeneficio, 
		cla.IdGrupoPrestacion, cla.ClasificacionGrupo, 
		cla.IdSubgrupoPrestacion, cla.ClasificacionSubgrupo, 
		cla.IdAperturaPrestacion, cla.ClasificacionApertura,

		ig.Glosa GlosaBeneficio,
		case when ig.Glosa = 'BENEFICIO DE HOSPITALIZACIÓN' or cat.IdCategorizacionCanal in (6, 12, 15, 16, 48) then 1 else 0 end Hospitalizacion,

		sd2.cantidad,
		sd2.MontoValorBeneficio as ValorPrestacionCLP,
		sd2.MontoReclamado as MontoReclamadoCLP,
		sd2.MontoLiquidado as MontoIndemnizarCLP,
		sd2.MontoLiquidado - sd2.MontoDeduciblePrestacion as ValorPagoCLP,
	
		case when sd2.IdLiquidacionDetalleEstado = 1 then 'APROBADA'
			 else 'RECHAZADA' 
		end Estado,
		
		--isnull(rt.glosa,'') RechazoTipo,

		pre.rutprestador as RutPrestador
		
into #siniestros1

from bos.bos.siniestro sin

inner join #titulares t on t.RutTitular = sin.RutTitular and (sin.FechaRecepcionLiquidacionVC between t.LiquidacionDesde and t.LiquidacionHasta) and (sin.FechaSiniestro >= t.PrestacionDesde)

inner join bos.bos.denuncio den on den.iddenuncio = sin.iddenuncio and sin.vigente = 1 and sin.IdPlanBeneficio not like 'DEN%'

inner join bos.bos.siniestrodocumento sd on sd.idsiniestro = sin.idsiniestro
inner join bos.bos.liquidaciondetalle sd2 on sd2.idSiniestroDocumento=sd.idSiniestroDocumento -- and sd2.IdLiquidacionDetalleEstado = 1

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

inner join Suscripcion.dbo.Persona p on p.idpersona = sin.IdTitular
inner join Suscripcion.dbo.Persona pb on pb.idpersona = sin.IdSiniestrado

left join bos.bos.liquidaciondetallerechazo sdr	on	sdr.idliquidaciondetalle=sd2.idliquidaciondetalle
-- left join bos.bos.RechazoTipo rt on	rt.idRechazoTipo=sdr.idRechazoTipo


select * from #siniestros1 where Estado <> 'RECHAZADA' order by ValorPrestacionCLP desc

--------------------------------------------------------------------------------
------------------------ DEMOGRAFICO -------------------------------------------
--------------------------------------------------------------------------------

drop table if exists #siniestros2
select *, case when EdadBeneficiario <= 14 then 1 else 0 end PacientePediatrico,
		  case when EdadBeneficiario >= 70 then 1 else 0 end PacienteGeriatrico
into #siniestros2
from #siniestros1

--------------------------------------------------------------------------------
------------------------ DIAGNOSTICOS ------------------------------------------
--------------------------------------------------------------------------------

drop table if exists #diagnosticos_sm0
select distinct sin.ruttitular, sin.rutsiniestrado, count(distinct di.Glosa) Diagnosticos, max(distinct di.Glosa) Diagnostico1, min(distinct di.Glosa) Diagnostico2
into #diagnosticos_sm0
from bos.bos.siniestro sin
inner join #siniestros1 s on s.rutsiniestrado = sin.rutsiniestrado
inner join aus.liquidacion.diagnostico di on sin.idcausaprimaria = di.idDiagnostico 
inner join bos.bos.denuncio den on sin.fecharecepcionliquidacionvc between '20190101' and GETDATE() and den.iddenuncio = sin.iddenuncio and sin.vigente=1
inner join bos.bos.siniestrodocumento sd on sd.idsiniestro = sin.idsiniestro
inner join bos.bos.liquidaciondetalle sd2 on sd2.idSiniestroDocumento=sd.idSiniestroDocumento and sd2.IdLiquidacionDetalleEstado = 1
left join #clasif cla on cast(cla.CodigoPrestacion as int) = cast(sd2.CodigoBeneficio as int)
inner join AUS.Siniestralidad.InstanciaGeneral ig on ig.Codigo=sd2.IdGrupo and (ig.codigo <> 300 and ig.codigo <> 700 and ig.codigo <> 800 and ig.codigo <> 900)
where sin.idcausaprimaria != 0 and (not iddiagnostico in(-1,16051) and not di.codigo like 'Z%' and not di.codigo like 'K0%' and not di.codigo like 'BBB') 
		and (ig.Glosa = 'BENEFICIOS DE SALUD MENTAL' or cla.ClasificacionSubgrupo = 'SALUD MENTAL')
group by sin.ruttitular, sin.rutsiniestrado

drop table if exists #diagnosticos_sm1
select ruttitular, sum(Diagnosticos) Diagnosticos
into #diagnosticos_sm1
from #diagnosticos_sm0
group by RutTitular

drop table if exists #siniestros2
select s.*, case when di.Diagnosticos is null then 0 else di.Diagnosticos end Diagnosticos
into #siniestros2
from #siniestros1 s
left join #diagnosticos_sm1 di on di.RutTitular = s.RutTitular
