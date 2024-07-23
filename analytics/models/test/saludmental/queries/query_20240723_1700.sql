--------------------------------------------------------------------------------
------------------------ CLASIFICACION PRESTACIONES ----------------------------
--------------------------------------------------------------------------------

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
where sp.ClasificacionSubgrupo = 'SALUD MENTAL'

--------------------------------------------------------------------------------
------------------------ SINIESTROS --------------------------------------------
--------------------------------------------------------------------------------

declare @fechadesde as datetime = '20240601'
declare @fechahasta as datetime = '20240701'

select sin.RutTitular,
		sin.RutSiniestrado RutBeneficiario, 
		
		den.NumeroDenuncio as NumeroSolicitud,
		sd2.fechabeneficio as FechaPrestacion, 
		sin.fecharecepcionliquidacionvc as FechaRecepcionLiquidacion,

		cast(sd2.CodigoBeneficio as int) CodigoBeneficio, 
		
		cla.IdGrupoPrestacion, cla.ClasificacionGrupo,
		cla.IdSubgrupoPrestacion, cla.ClasificacionSubgrupo,
		cla.IdAperturaPrestacion, cla.ClasificacionApertura,

		sd2.cantidad as Cantidad,	
		
		sd2.MontoValorBeneficio as ValorPrestacionCLP, 
		sd2.MontoConversionBeneficio as ValorPrestacionUF,
		
		sd2.Montoreclamado as ValorReclamadoCLP,
		sd2.MontoConversionReclamado as ValorReclamadoUF,
		
		sd2.Montoliquidado as ValorPagoCLP,
		sd2.MontoConversionLiquidado as ValorPagoUF, 

		case when isa.glosa = 'FONASA' then 'FONASA' else 'NO FONASA' end Prevision,
		pre.rutprestador as RutPrestador,
		pre.nombreprestador as NombrePrestador

into #siniestros0

from bos.bos.siniestro sin

inner join bos.bos.denuncio den on den.iddenuncio = sin.iddenuncio and sin.vigente = 1 and sin.fecharecepcionliquidacionvc >= @fechadesde and sin.fecharecepcionliquidacionvc < @fechahasta and sin.FechaSiniestro >= @fechadesde
inner join bos.bos.siniestrodocumento sd on sd.idsiniestro = sin.idsiniestro
inner join bos.bos.liquidaciondetalle sd2 on sd2.idSiniestroDocumento=sd.idSiniestroDocumento and sd2.IdLiquidacionDetalleEstado = 1

inner join #clasif cla on cast(cla.CodigoPrestacion as int) = cast(sd2.CodigoBeneficio as int)

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

select  RIGHT('0000000000' + CONVERT(VARCHAR(10), RutTitular), 12) as RutTitular, 
		RIGHT('0000000000' + CONVERT(VARCHAR(10), RutBeneficiario), 12) as RutBeneficiario,
		NumeroSolicitud,
		IdGrupoPrestacion, ClasificacionGrupo, IdSubgrupoPrestacion, ClasificacionSubgrupo, IdAperturaPrestacion, ClasificacionApertura,
		sum(Cantidad) Cantidad, 
		sum(ValorPrestacionCLP) ValorPrestacionCLP, sum(ValorPrestacionCLP) / sum(Cantidad) CostoUnitarioCLP,
		sum(ValorPrestacionUF) ValorPrestacionUF, sum(ValorPrestacionUF) / sum(Cantidad) CostoUnitarioUF,
		sum(ValorReclamadoCLP) ValorReclamadoCLP, sum(ValorReclamadoUF) ValorReclamadoUF, 
		sum(ValorPagoUF) ValorPagoUF, sum(ValorPagoCLP) ValorPagoCLP,
		FechaPrestacion, FechaRecepcionLiquidacion, Prevision, 
		case when RutPrestador = 'Sin rut prestador' then RutPrestador else RIGHT('0000000000' + CONVERT(VARCHAR(10), RutPrestador), 12) end RutPrestador,
		NombrePrestador
into #siniestros1
from #siniestros0
group by RutTitular, RutBeneficiario, NumeroSolicitud, FechaPrestacion, FechaRecepcionLiquidacion, Prevision, RutPrestador, NombrePrestador,
		 IdGrupoPrestacion, ClasificacionGrupo, IdSubgrupoPrestacion, ClasificacionSubgrupo, IdAperturaPrestacion, ClasificacionApertura
having sum(Cantidad) > 0 and sum(Cantidad) < 100 and sum(ValorPrestacionCLP) > 0

--------------------------------------------------------------------------------
------------------------ CRITERIOS OUTLIER -------------------------------------
--------------------------------------------------------------------------------

-- drop table if exists #criteriooutlier
select  co.IdGrupoPrestacion, co.IdSubgrupoPrestacion, co.IdAperturaPrestacion,
		co.CriterioCantidadAlta, co.CriterioCostoUnitarioBajo, co.CriterioCostoUnitarioAlto,
		es.IdEstadistico, es.DescripcionDetalle, es.FechaModelo,
		ma.IdModeloAnalitico, ma.AreaProposito, ma.Descripcion, 
		mg.GlosaModeloGenerico, mg.TipoMachineLearning
into #criteriooutlier
from DesarrolloBi.Modelo.ModeloAnalitico ma
inner join DesarrolloBI.Modelo.ModeloGenerico mg on mg.IdModeloGenerico = ma.IdModeloGenerico and ma.Vigencia = 1 and mg.Vigencia = 1
inner join DesarrolloBI.Modelo.Estadistico es on es.IdModeloAnalitico = ma.IdModeloAnalitico and es.Vigencia = 1
inner join DesarrolloBI.Modelo.CriterioOutlierLiquidacion co on co.IdEstadistico = es.IdEstadistico and co.Vigencia = 1


-- drop table if exists #siniestros2
select  sin.*, co.CriterioCantidadAlta, co.CriterioCostoUnitarioBajo, co.CriterioCostoUnitarioAlto,
		case when sin.Cantidad > co.CriterioCantidadAlta then 1 else 0 end OutlierCantidadAlta,
		case when sin.CostoUnitarioCLP >= co.CriterioCostoUnitarioAlto then 1 else 0 end OutlierCostoAlto,
		case when sin.CostoUnitarioCLP <= co.CriterioCostoUnitarioBajo then 1 else 0 end OutlierCostoBajo
into #siniestros2
from #siniestros1 sin
left join #criteriooutlier co on co.IdGrupoPrestacion = sin.IdGrupoPrestacion 
									and co.IdSubgrupoPrestacion = sin.IdSubgrupoPrestacion 
									and co.IdAperturaPrestacion = sin.IdAperturaPrestacion

-- drop table if exists #siniestros3
select * into #siniestros3
from #siniestros2
where OutlierCantidadAlta = 0 and OutlierCostoBajo = 0 and OutlierCostoAlto = 0

--------------------------------------------------------------------------------
------------------------ EXPORTAR RESULTADOS -----------------------------------
--------------------------------------------------------------------------------

select	RutTitular, RutBeneficiario,
		NumeroSolicitud,
		IdGrupoPrestacion, ClasificacionGrupo, IdSubgrupoPrestacion, ClasificacionSubgrupo, IdAperturaPrestacion, ClasificacionApertura,
		Cantidad, ValorPrestacionCLP, ValorPrestacionUF, CostoUnitarioCLP, ValorReclamadoCLP, ValorPagoUF, ValorPagoCLP,
		FechaPrestacion, FechaRecepcionLiquidacion, Prevision,
		RutPrestador, NombrePrestador
from #siniestros3