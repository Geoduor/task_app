// Shape returned to clients. Keeping a dedicated response DTO decouples the
// wire format from the Mongoose document (e.g. _id -> id).
export class TaskResponseDto {
  id!: string;
  title!: string;
  completed!: boolean;
  createdAt!: Date;
  updatedAt!: Date;
}
