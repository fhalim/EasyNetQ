/****** Object:  StoredProcedure [dbo].[USP_GetNextBatchOfMessages]    Script Date: 11/25/2011 15:08:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetNextBatchOfMessages]
 @rows INT = 1000, 
 @status TINYINT = 0,
 @WakeTime DATETIME

AS
/******************************************************************************
**		File: uspGetNextBatchOfMessages.sql
**		Name: uspGetNextBatchOfMessages 
**		Desc: Example table polling technique for scheduled tasks
**
**		Auth: Steve Smith
**		Date: 20111115
**
**      Uses: @rows = number of rows to select for update
**			  @status = status to seek 
**			  @waketime = seek date/time EARLIER than this
*******************************************************************************
**		Change History
*******************************************************************************
**		Date:		Author:				Description:
**		--------	--------			-------------------------------------------
**		20111115	Steve Smith			Original creation for demonstration
*******************************************************************************/


-- NB: WITH statements require a ';' on the statement immediately previous
BEGIN TRANSACTION;


-- Uses a CTE to allow ORDER BY WakeTime, and to throttle by @rows
-- (because you cannot ORDER BY an UPDATE statement)
WITH Results as
(
SELECT TOP (@rows) WorkItemID, WakeTime 
FROM WorkItemStatus ws
WHERE ws.Status = @status and ws.Waketime <= @WakeTime
ORDER BY ws.WakeTime ASC
)
-- Performs the UPDATE and OUTPUTs the INSERTED. fields to the calling app
UPDATE WorkItemStatus
SET Status = 2
OUTPUT INSERTED.WorkItemID, 2 as Status, INSERTED.WakeTime, wi.BindingKey, wi.InnerMessage
FROM WorkItemStatus ws
INNER JOIN Results r       -- this JOIN filters our UPDATE to the @rows SELECTed
ON r.WorkItemID = ws.WorkItemID
INNER JOIN WorkItems wi    -- this JOIN is purely to allow OUTPUT of Bindingkey and InnerMessage
ON ws.WorkItemID = wi.WorkItemID

IF @@ERROR > 0 
	ROLLBACK TRANSACTION
ELSE
	COMMIT TRANSACTION